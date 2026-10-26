import XCTest
import Combine
import AVFoundation
@testable import myTV

private final class MockChannelRepository: ChannelRepository {
    func fetchChannels() async throws -> [Channel] { [] }
    func fetchStreams(channelId: String) async throws -> [myTV.Stream] { [] }
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

final class StreamPlaybackTests: XCTestCase {

    @MainActor
    private func makeModel() -> StreamListViewModel {
        StreamListViewModel(
            fetchStreams: DefaultFetchStreamsForChannelUseCase(repository: MockChannelRepository()),
            reachability: MockReachability(),
            haptics: MockHaptics()
        )
    }

    private func stream(_ id: String) -> myTV.Stream {
        let bundle = Bundle(for: Self.self)
        let audioURL = bundle.url(forResource: "silence", withExtension: "wav") ?? URL(string: "https://fixture.invalid/\(id).m3u8")!
        return myTV.Stream(
            id: id,
            title: id,
            url: audioURL.absoluteString,
            quality: nil
        )
    }

    @MainActor
    func testDismissalIgnoresAlreadyQueuedFailure() async throws {
        let model = makeModel()
        let first = stream("first")
        model.playWithFallback(startingFrom: first, allStreams: [first])
        model.isPresentingPlayer = true

        if let currentItem = model.player?.currentItem {
            NotificationCenter.default.post(name: .AVPlayerItemFailedToPlayToEndTime, object: currentItem)
        }
        model.dismissPlayer()
        try await Task.sleep(for: .milliseconds(100))

        XCTAssertNil(model.player)
        XCTAssertNil(model.playbackError)
        XCTAssertFalse(model.isPresentingPlayer)
        XCTAssertFalse(model.isPreparingPlayback)
    }

    @MainActor
    func testReplacementIgnoresPreviousItemsQueuedFailure() async throws {
        let model = makeModel()
        defer { model.teardown() }

        let first = stream("first")
        let second = stream("second")
        model.playWithFallback(startingFrom: first, allStreams: [first])

        if let currentItem = model.player?.currentItem {
            NotificationCenter.default.post(name: .AVPlayerItemFailedToPlayToEndTime, object: currentItem)
        }

        model.playWithFallback(startingFrom: second, allStreams: [second])
        let replacement = model.player
        try await Task.sleep(for: .milliseconds(100))

        XCTAssertTrue(model.player === replacement)
        XCTAssertNil(model.playbackError)
    }

    @MainActor
    func testCurrentItemFailureAdvancesThenStopsAfterFinalFailure() async throws {
        let model = makeModel()
        let first = stream("first")
        let second = stream("second")
        model.playWithFallback(startingFrom: first, allStreams: [first, second])
        let initial = model.player

        if let currentItem = initial?.currentItem {
            NotificationCenter.default.post(name: .AVPlayerItemFailedToPlayToEndTime, object: currentItem)
        }
        try await Task.sleep(for: .milliseconds(100))

        XCTAssertNotNil(model.player)
    }
}
