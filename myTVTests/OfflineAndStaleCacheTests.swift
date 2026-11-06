import XCTest
import Combine
@testable import myTV

private final class ControllableMockReachability: ReachabilityService {
    private let subject: CurrentValueSubject<Bool, Never>

    init(initial: Bool) {
        self.subject = CurrentValueSubject<Bool, Never>(initial)
    }

    var isOnline: Bool {
        subject.value
    }

    var isOnlinePublisher: AnyPublisher<Bool, Never> {
        subject.eraseToAnyPublisher()
    }

    func setOnline(_ online: Bool) {
        subject.send(online)
    }
}

private final class ControllableMockIPTVService: IPTVAPIService {
    var shouldFailChannels = false
    var shouldFailStreams = false

    func fetchChannels() async throws -> [ChannelDTO] {
        if shouldFailChannels {
            throw URLError(.notConnectedToInternet)
        }
        return [
            ChannelDTO(
                id: "ch-live-1",
                name: "Alpha TV",
                alt_names: [],
                network: nil,
                owners: [],
                country: "US",
                categories: ["news"],
                is_nsfw: false,
                launched: nil,
                closed: nil,
                replaced_by: nil,
                website: nil
            ),
            ChannelDTO(
                id: "ch-live-2",
                name: "Beta Sports",
                alt_names: [],
                network: nil,
                owners: [],
                country: "UK",
                categories: ["sports"],
                is_nsfw: false,
                launched: nil,
                closed: nil,
                replaced_by: nil,
                website: nil
            )
        ]
    }

    func fetchLogos() async throws -> [LogoDTO] { [] }
    func fetchCategoryPlaylist(_ id: String) async throws -> [M3UChannel] { [] }
    func fetchStreams() async throws -> [StreamDTO] {
        if shouldFailStreams {
            throw URLError(.notConnectedToInternet)
        }
        return [
            StreamDTO(
                channel: "ch-live-1",
                feed: nil,
                title: "Live 1080p",
                url: "https://fixture.invalid/ch-live-1.m3u8",
                referrer: nil,
                user_agent: nil,
                quality: "1080p"
            )
        ]
    }
}

private final class MockDiskCache: ChannelCache {
    private var storage: [ChannelDTO]?

    init(seed: [ChannelDTO]? = nil) {
        self.storage = seed
    }

    var entryCount: Int { storage?.count ?? 0 }
    var fileSizeBytes: Int { 1024 }
    var formattedFileSize: String { "1 KB" }

    func save(_ channels: [ChannelDTO]) {
        self.storage = channels
    }

    func load() -> [ChannelDTO]? {
        storage
    }

    func clear() {
        storage = nil
    }
}

@MainActor
final class OfflineAndStaleCacheTests: XCTestCase {

    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUp() async throws {
        try await super.setUp()
        suiteName = "offline-stale-tests-" + UUID().uuidString
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() async throws {
        defaults.removePersistentDomain(forName: suiteName)
        try await super.tearDown()
    }

    func testColdLaunchOfflineWithEmptyCacheShowsErrorState() async throws {
        let api = ControllableMockIPTVService()
        api.shouldFailChannels = true
        let emptyCache = MockDiskCache(seed: nil)
        let repo = ChannelRepositoryImpl(api: api, cache: emptyCache)
        let useCase = DefaultFetchChannelsUseCase(repository: repo)
        let reachability = ControllableMockReachability(initial: false)
        let favorites = FavoriteChannelStore(defaults: defaults)

        let vm = ChannelListViewModel(
            fetchChannels: useCase,
            reachability: reachability,
            haptics: AppDI.shared.getHaptics(),
            favorites: favorites
        )

        await vm.load()

        guard case .error = vm.state else {
            XCTFail("Cold launch offline with no cache must yield .error state but got \(vm.state)")
            return
        }
        XCTAssertTrue(vm.channels.isEmpty)
        XCTAssertTrue(vm.showOfflineBanner)
    }

    func testColdLaunchOfflineWithStaleCacheLoadsCachedChannelsAndShowsBanner() async throws {
        let api = ControllableMockIPTVService()
        api.shouldFailChannels = true

        let staleSeed = [
            ChannelDTO(
                id: "stale-1",
                name: "Stale News Network",
                alt_names: [],
                network: nil,
                owners: [],
                country: "US",
                categories: ["news"],
                is_nsfw: false,
                launched: nil,
                closed: nil,
                replaced_by: nil,
                website: nil
            )
        ]
        let staleCache = MockDiskCache(seed: staleSeed)
        let repo = ChannelRepositoryImpl(api: api, cache: staleCache)
        let useCase = DefaultFetchChannelsUseCase(repository: repo)
        let reachability = ControllableMockReachability(initial: false)
        let favorites = FavoriteChannelStore(defaults: defaults)

        let vm = ChannelListViewModel(
            fetchChannels: useCase,
            reachability: reachability,
            haptics: AppDI.shared.getHaptics(),
            favorites: favorites
        )

        await vm.load()

        guard case .loaded = vm.state else {
            XCTFail("Cold launch offline with stale cache should transition to .loaded, got \(vm.state)")
            return
        }
        XCTAssertEqual(vm.channels.count, 1)
        XCTAssertEqual(vm.channels.first?.id, "stale-1")
        XCTAssertEqual(vm.channels.first?.name, "Stale News Network")
        XCTAssertTrue(vm.showOfflineBanner, "Offline banner must be displayed when offline")
    }

    func testFavoritesPersistIndependentlyAcrossOfflineRelaunchAndCacheClear() async throws {
        let favorites = FavoriteChannelStore(defaults: defaults, ownerID: UUID())
        favorites.save(["stale-favorite-ch"])

        let api = ControllableMockIPTVService()
        api.shouldFailChannels = true

        let seeded = [
            ChannelDTO(
                id: "stale-favorite-ch",
                name: "Favorite Stale Channel",
                alt_names: [],
                network: nil,
                owners: [],
                country: "US",
                categories: ["general"],
                is_nsfw: false,
                launched: nil,
                closed: nil,
                replaced_by: nil,
                website: nil
            ),
            ChannelDTO(
                id: "stale-other-ch",
                name: "Other Stale Channel",
                alt_names: [],
                network: nil,
                owners: [],
                country: "US",
                categories: ["general"],
                is_nsfw: false,
                launched: nil,
                closed: nil,
                replaced_by: nil,
                website: nil
            )
        ]
        let diskCache = MockDiskCache(seed: seeded)
        let repo = ChannelRepositoryImpl(api: api, cache: diskCache)
        let useCase = DefaultFetchChannelsUseCase(repository: repo)
        let reachability = ControllableMockReachability(initial: false)

        let vm = ChannelListViewModel(
            fetchChannels: useCase,
            reachability: reachability,
            haptics: AppDI.shared.getHaptics(),
            favorites: favorites
        )

        await vm.load()
        XCTAssertTrue(vm.favoriteChannelIDs.contains("stale-favorite-ch"))

        // Scope to favorites
        vm.setScope(.favorites)
        let favs = vm.groupedResult.flatMap { $0.1 }
        XCTAssertEqual(favs.count, 1)
        XCTAssertEqual(favs.first?.id, "stale-favorite-ch")

        // Clearing channel disk cache must NOT delete user favorites
        diskCache.clear()
        XCTAssertEqual(favorites.load(), ["stale-favorite-ch"], "Favorites store must be independent of catalog cache")
    }

    func testOfflineStreamLoadErrorHandlingDoesNotCorruptUI() async throws {
        let repo = ChannelRepositoryImpl(api: ControllableMockIPTVService(), cache: MockDiskCache())
        let useCase = DefaultFetchStreamsForChannelUseCase(repository: repo)
        let reachability = ControllableMockReachability(initial: false)

        let streamVM = StreamListViewModel(
            fetchStreams: useCase,
            reachability: reachability,
            haptics: AppDI.shared.getHaptics()
        )

        // Offline stream loading attempt
        let apiFailing = ControllableMockIPTVService()
        apiFailing.shouldFailStreams = true
        let failingRepo = ChannelRepositoryImpl(api: apiFailing, cache: MockDiskCache())
        let failingUseCase = DefaultFetchStreamsForChannelUseCase(repository: failingRepo)
        let failingStreamVM = StreamListViewModel(
            fetchStreams: failingUseCase,
            reachability: reachability,
            haptics: AppDI.shared.getHaptics()
        )

        await failingStreamVM.loadStreams(channelId: "any-channel")

        guard case .error = failingStreamVM.state else {
            XCTFail("Failed offline stream fetch must yield .error state")
            return
        }
        XCTAssertTrue(failingStreamVM.streams.isEmpty)
        XCTAssertTrue(failingStreamVM.showOfflineBanner)

        // Simulating transition back online triggers automatic stream reload
        reachability.setOnline(true)
        try await Task.sleep(for: .milliseconds(50))
        XCTAssertFalse(streamVM.showOfflineBanner)
    }
}
