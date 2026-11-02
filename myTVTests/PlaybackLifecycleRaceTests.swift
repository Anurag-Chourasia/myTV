import XCTest
import Combine
import AVFoundation
@testable import myTV

private final class MockChannelRepository: ChannelRepository {
    var delayNanoseconds: UInt64 = 0
    var shouldFail = false
    func fetchChannels() async throws -> [Channel] { [] }
    func fetchStreams(channelId: String) async throws -> [myTV.Stream] {
        if delayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: delayNanoseconds)
        }
        if shouldFail { throw URLError(.badServerResponse) }
        return [
            myTV.Stream(id: "stream-\(channelId)", title: "Stream \(channelId)", url: "https://fixture.invalid/\(channelId).m3u8", quality: "1080p")
        ]
    }
    func clearCache() {}
}

private final class MockReachability: ReachabilityService {
    let isOnline = true
    var isOnlinePublisher: AnyPublisher<Bool, Never> { Empty().eraseToAnyPublisher() }
}

private final class MockHaptics: HapticService {
    func selection() {}
    func impact(_ style: ImpactStyle) {}
    func notification(_ type: NotificationType) {}
}

@MainActor
final class PlaybackLifecycleRaceTests: XCTestCase {

    private func makeModel(repo: MockChannelRepository = MockChannelRepository(), nc: NotificationCenter = NotificationCenter()) -> (StreamListViewModel, MockChannelRepository, NotificationCenter) {
        let model = StreamListViewModel(
            fetchStreams: DefaultFetchStreamsForChannelUseCase(repository: repo),
            reachability: MockReachability(),
            haptics: MockHaptics(),
            notificationCenter: nc
        )
        return (model, repo, nc)
    }

    private func stream(_ id: String) -> myTV.Stream {
        let bundle = Bundle(for: Self.self)
        let fallbackURL = URL(fileURLWithPath: "/dev/null")
        let audioURL = bundle.url(forResource: "silence", withExtension: "wav") ?? URL(string: "https://fixture.invalid/\(id).m3u8") ?? fallbackURL
        return myTV.Stream(
            id: id,
            title: id,
            url: audioURL.absoluteString,
            quality: nil
        )
    }

    func testRapidChannelSwitchingCancelsInFlightStreamFetch() async throws {
        let repo = MockChannelRepository()
        repo.delayNanoseconds = 150_000_000 // 150ms
        let (model, _, _) = makeModel(repo: repo)

        // Kick off fetch for channel A
        Task { await model.loadStreams(channelId: "channel-A") }
        try await Task.sleep(for: .milliseconds(20))

        // Immediately switch to channel B
        repo.delayNanoseconds = 0
        await model.loadStreams(channelId: "channel-B")

        // Wait for old task's original duration to expire
        try await Task.sleep(for: .milliseconds(200))

        // State must reflect channel B, not superseded channel A
        XCTAssertEqual(model.streams.count, 1)
        XCTAssertEqual(model.streams.first?.id, "stream-channel-B")
    }

    func testLeavingDuringPreparationTeardownInvalidatesCallbacks() async throws {
        let (model, _, nc) = makeModel()
        let s = stream("prep-test")

        model.playWithFallback(startingFrom: s, allStreams: [s])
        XCTAssertTrue(model.isPreparingPlayback)

        let initialPlayer = model.player
        let initialItem = initialPlayer?.currentItem

        // User rapidly dismisses player while preparing
        model.dismissPlayer()
        XCTAssertFalse(model.isPreparingPlayback)
        XCTAssertNil(model.player)

        // Obsolete failure notification arrives from network/AVPlayer
        if let initialItem {
            nc.post(name: .AVPlayerItemFailedToPlayToEndTime, object: initialItem)
        }
        try await Task.sleep(for: .milliseconds(50))

        // Obsolete callback must NOT resurrect playback or set error
        XCTAssertNil(model.player)
        XCTAssertNil(model.playbackError)
        XCTAssertFalse(model.isPresentingPlayer)
    }

    func testAudioInterruptionBeganPausesPlaybackAndEndedResumes() async throws {
        let (model, _, nc) = makeModel()
        let s = stream("audio-interruption")

        model.playWithFallback(startingFrom: s, allStreams: [s])
        model.isPresentingPlayer = true

        let player = try XCTUnwrap(model.player)
        player.play()

        // 1. Interruption Began (e.g. phone call received)
        nc.post(
            name: AVAudioSession.interruptionNotification,
            object: nil,
            userInfo: [AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.began.rawValue]
        )
        try await Task.sleep(for: .milliseconds(50))
        XCTAssertEqual(player.timeControlStatus, .paused)

        // 2. Interruption Ended with shouldResume option
        nc.post(
            name: AVAudioSession.interruptionNotification,
            object: nil,
            userInfo: [
                AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.ended.rawValue,
                AVAudioSessionInterruptionOptionKey: AVAudioSession.InterruptionOptions.shouldResume.rawValue
            ]
        )
        try await Task.sleep(for: .milliseconds(50))
        XCTAssertEqual(player.timeControlStatus, .waitingToPlayAtSpecifiedRate)
    }

    func testHeadphoneDisconnectPausesPlayback() async throws {
        let (model, _, nc) = makeModel()
        let s = stream("headphone-disconnect")

        model.playWithFallback(startingFrom: s, allStreams: [s])
        model.isPresentingPlayer = true

        let player = try XCTUnwrap(model.player)
        player.play()

        // Post route change notification with oldDeviceUnavailable reason
        nc.post(
            name: AVAudioSession.routeChangeNotification,
            object: nil,
            userInfo: [AVAudioSessionRouteChangeReasonKey: AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue]
        )
        try await Task.sleep(for: .milliseconds(50))
        XCTAssertEqual(player.timeControlStatus, .paused)
    }

    func testBackgroundTransitionPausesModalPlayback() async throws {
        let (model, _, nc) = makeModel()
        let s = stream("background-test")

        model.playWithFallback(startingFrom: s, allStreams: [s])
        model.isPresentingPlayer = true

        let player = try XCTUnwrap(model.player)
        player.play()

        // Post didEnterBackgroundNotification
        nc.post(
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        try await Task.sleep(for: .milliseconds(50))
        XCTAssertEqual(player.timeControlStatus, .paused)
    }
}
