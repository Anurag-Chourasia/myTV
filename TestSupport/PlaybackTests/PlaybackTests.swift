import XCTest
import Combine
import AVFoundation
@testable import Playback

private final class Repository: ChannelRepository {
    func fetchChannels() async throws -> [Channel] { [] }
    func fetchStreams(channelId: String) async throws -> [Playback.Stream] { [] }
    func clearCache() {}
}
private final class Reachability: ReachabilityService {
    let isOnline = true
    var isOnlinePublisher: AnyPublisher<Bool, Never> { Empty().eraseToAnyPublisher() }
}
private final class Haptics: HapticService {
    func selection() {}
    func impact(_ style: ImpactStyle) {}
    func notification(_ type: NotificationType) {}
}
final class PlaybackTests: XCTestCase {
    @MainActor private func makeModel() -> StreamListViewModel {
        StreamListViewModel(fetchStreams: DefaultFetchStreamsForChannelUseCase(repository: Repository()),
                            reachability: Reachability(), haptics: Haptics())
    }
    private func stream(_ id: String) -> Playback.Stream {
        Playback.Stream(id: id, title: id, url: Bundle.module.url(forResource: "silence", withExtension: "wav")!.absoluteString, quality: nil)
    }
    @MainActor func testDismissalIgnoresAlreadyQueuedFailure() async throws {
        let model = makeModel()
        let first = stream("first")
        model.playWithFallback(startingFrom: first, allStreams: [first])
        model.isPresentingPlayer = true
        NotificationCenter.default.post(name: .AVPlayerItemFailedToPlayToEndTime, object: model.player!.currentItem!)
        model.dismissPlayer()
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertNil(model.player)
        XCTAssertNil(model.playbackError)
        XCTAssertFalse(model.isPresentingPlayer)
        XCTAssertFalse(model.isPreparingPlayback)
    }
    @MainActor func testReplacementIgnoresPreviousItemsQueuedFailure() async throws {
        let model = makeModel()
        defer { model.teardown() }
        let first = stream("first"), second = stream("second")
        model.playWithFallback(startingFrom: first, allStreams: [first])
        NotificationCenter.default.post(name: .AVPlayerItemFailedToPlayToEndTime, object: model.player!.currentItem!)
        model.playWithFallback(startingFrom: second, allStreams: [second])
        let replacement = model.player
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertTrue(model.player === replacement)
        XCTAssertNil(model.playbackError)
    }
    @MainActor func testCurrentItemFailureAdvancesThenStopsAfterFinalFailure() async throws {
        let model = makeModel()
        let first = stream("first"), second = stream("second")
        model.playWithFallback(startingFrom: first, allStreams: [first, second])
        let initial = model.player
        NotificationCenter.default.post(name: .AVPlayerItemFailedToPlayToEndTime, object: initial!.currentItem!)
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertNotNil(model.player)
        XCTAssertFalse(model.player === initial)
        NotificationCenter.default.post(name: .AVPlayerItemFailedToPlayToEndTime, object: model.player!.currentItem!)
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertNil(model.player)
        XCTAssertNotNil(model.playbackError)
        XCTAssertFalse(model.isPreparingPlayback)
        XCTAssertFalse(model.isPresentingPlayer)
    }
}
