import XCTest
@testable import myTV

private typealias Stream = myTV.Stream

@MainActor
final class StreamListViewModelTests: XCTestCase {

    private final class MockStreamRepository: ChannelRepository {
        func fetchChannels() async throws -> [myTV.Channel] { [] }
        func fetchStreams(channelId: String) async throws -> [Stream] {
            if channelId == "error-channel" { throw URLError(.badServerResponse) }
            if channelId == "empty-channel" { return [] }
            return [
                Stream(id: "stream-1", title: "1080p Stream", url: "https://example.com/live.m3u8", quality: "1080p")
            ]
        }
        func clearCache() {}
    }

    private func makeViewModel() -> StreamListViewModel {
        let repo = MockStreamRepository()
        let useCase = DefaultFetchStreamsForChannelUseCase(repository: repo)
        return StreamListViewModel(
            fetchStreams: useCase,
            reachability: ReachabilityServiceImpl(),
            haptics: AppDI.shared.getHaptics()
        )
    }

    func testLoadStreamsPopulatesStreamsForChannel() async throws {
        let viewModel = makeViewModel()
        XCTAssertTrue(viewModel.streams.isEmpty)

        await viewModel.loadStreams(channelId: "valid-channel")

        XCTAssertEqual(viewModel.streams.count, 1)
        XCTAssertEqual(viewModel.streams.first?.title, "1080p Stream")
        if case .loaded = viewModel.state {
            // expected
        } else {
            XCTFail("Expected state to be .loaded but got \(viewModel.state)")
        }
    }

    func testLoadStreamsEmptyReturnsEmptyState() async throws {
        let viewModel = makeViewModel()

        await viewModel.loadStreams(channelId: "empty-channel")

        XCTAssertTrue(viewModel.streams.isEmpty)
        if case .empty = viewModel.state {
            // expected
        } else {
            XCTFail("Expected state to be .empty but got \(viewModel.state)")
        }
    }

    func testLoadStreamsErrorSetsErrorState() async throws {
        let viewModel = makeViewModel()

        await viewModel.loadStreams(channelId: "error-channel")

        XCTAssertTrue(viewModel.streams.isEmpty)
        if case .error = viewModel.state {
            // expected
        } else {
            XCTFail("Expected state to be .error but got \(viewModel.state)")
        }
    }

    func testDismissPlayerResetsPlayerState() {
        let viewModel = makeViewModel()
        viewModel.dismissPlayer()

        XCTAssertNil(viewModel.player)
        XCTAssertFalse(viewModel.isPresentingPlayer)
        XCTAssertFalse(viewModel.isPreparingPlayback)
    }

    func testClearPlaybackError() {
        let viewModel = makeViewModel()
        viewModel.playbackError = "Network connection failed"
        XCTAssertTrue(viewModel.isShowingPlaybackError)

        viewModel.clearPlaybackError()
        XCTAssertFalse(viewModel.isShowingPlaybackError)
        XCTAssertNil(viewModel.playbackError)
    }
}
