import XCTest
import Combine
@testable import myTV

@MainActor
final class CompleteJourneyTests: XCTestCase {

    override func setUp() async throws {
        try await super.setUp()
        UserDefaults.standard.set("stub", forKey: "developer.source")
        UserDefaults.standard.set("showcase", forKey: "developer.scenario")
    }

    override func tearDown() async throws {
        UserDefaults.standard.removeObject(forKey: "developer.source")
        UserDefaults.standard.removeObject(forKey: "developer.scenario")
        try await super.tearDown()
    }

    func testDiscoverSearchPlaybackFavoriteAndRelaunchJourney() async throws {
        let suite = "mytv-journey-tests-" + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        // 1. Launch & Discover
        let store = FavoriteChannelStore(defaults: defaults)
        let channelListVM = AppDI.shared.makeChannelListViewModel(favorites: store)
        await channelListVM.load()

        guard case .loaded = channelListVM.state else {
            XCTFail("Expected channel list state to be .loaded but got \(channelListVM.state)")
            return
        }
        XCTAssertEqual(channelListVM.channels.count, 8, "Showcase scenario should load 8 channels")

        // 2. Search / Filter with debounce wait
        channelListVM.searchText = "NASA"
        try await Task.sleep(for: .milliseconds(350))

        let matching = channelListVM.groupedResult.flatMap(\.1)
        XCTAssertFalse(matching.isEmpty, "Search for 'NASA' should return matching channels")
        XCTAssertTrue(matching.allSatisfy { $0.name.localizedCaseInsensitiveContains("NASA") })

        // Clear search
        channelListVM.searchText = ""
        try await Task.sleep(for: .milliseconds(350))

        // 3. Select channel & fetch streams
        let targetChannel = try XCTUnwrap(channelListVM.channels.first { $0.id == "nasa-tv-hd" })
        let streamListVM = AppDI.shared.makeStreamListViewModel()
        await streamListVM.loadStreams(channelId: targetChannel.id)

        guard case .loaded = streamListVM.state else {
            XCTFail("Expected streams state to be .loaded but got \(streamListVM.state)")
            return
        }
        XCTAssertFalse(streamListVM.streams.isEmpty, "Target channel should have active streams")
        let primaryStream = streamListVM.streams[0]

        // 4. Playback and dismissal via playWithFallback
        streamListVM.playWithFallback(startingFrom: primaryStream, allStreams: streamListVM.streams)
        XCTAssertTrue(streamListVM.isPreparingPlayback)

        streamListVM.dismissPlayer()
        XCTAssertFalse(streamListVM.isPresentingPlayer)
        XCTAssertFalse(streamListVM.isPreparingPlayback)
        XCTAssertNil(streamListVM.player)

        // 5. Favorite the channel
        XCTAssertFalse(channelListVM.favoriteChannelIDs.contains(targetChannel.id))
        channelListVM.toggleFavorite(targetChannel.id)
        XCTAssertTrue(channelListVM.favoriteChannelIDs.contains(targetChannel.id))

        // 6. Filter by Favorites Scope
        channelListVM.setGrouping(.name)
        channelListVM.setScope(.favorites)
        let favoriteResults = channelListVM.groupedResult.flatMap(\.1)
        let uniqueFavoriteChannels = Set(favoriteResults.map(\.id))
        XCTAssertEqual(uniqueFavoriteChannels, [targetChannel.id])

        // 7. Terminate & Relaunch simulation
        let relaunchedStore = FavoriteChannelStore(defaults: try XCTUnwrap(UserDefaults(suiteName: suite)))
        let relaunchedVM = AppDI.shared.makeChannelListViewModel(favorites: relaunchedStore)
        await relaunchedVM.load()

        XCTAssertTrue(relaunchedVM.favoriteChannelIDs.contains(targetChannel.id),
                      "Favorite selection must survive app termination and relaunch")

        // 8. Stream unavailable recovery verification
        streamListVM.playbackError = "The media playback failed to start."
        XCTAssertTrue(streamListVM.isShowingPlaybackError)
        streamListVM.clearPlaybackError()
        XCTAssertFalse(streamListVM.isShowingPlaybackError)
        XCTAssertNil(streamListVM.playbackError)
    }
}
