import XCTest
@testable import myTV

private typealias Stream = myTV.Stream

final class DomainUseCasesTests: XCTestCase {

    private final class MockChannelRepository: ChannelRepository {
        var channels: [Channel] = []
        var streams: [Stream] = []
        var clearCacheCalled = false
        var cachedEntryCount: Int = 42
        var formattedCacheSize: String = "128 KB"

        func fetchChannels() async throws -> [Channel] {
            channels
        }

        func fetchStreams(channelId: String) async throws -> [Stream] {
            streams
        }

        func clearCache() {
            clearCacheCalled = true
        }
    }

    func testFetchChannelsUseCase() async throws {
        let repo = MockChannelRepository()
        let channel = Channel(
            id: "ch-1",
            name: "News Channel",
            country: "US",
            categories: ["News"],
            isNSFW: false,
            logoURL: nil,
            hasStreams: true
        )
        repo.channels = [channel]

        let useCase = DefaultFetchChannelsUseCase(repository: repo)
        let result = try await useCase.execute()

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.id, "ch-1")
    }

    func testFetchStreamsForChannelUseCase() async throws {
        let repo = MockChannelRepository()
        let stream = Stream(
            id: "st-1",
            title: "Live 1080p",
            url: "https://example.com/stream.m3u8",
            quality: "1080p"
        )
        repo.streams = [stream]

        let useCase = DefaultFetchStreamsForChannelUseCase(repository: repo)
        let result = try await useCase.execute(channelId: "ch-1")

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.id, "st-1")
    }

    func testManageChannelCacheUseCase() async throws {
        let repo = MockChannelRepository()
        let useCase = DefaultManageChannelCacheUseCase(repository: repo)

        XCTAssertEqual(useCase.getCachedEntryCount(), 42)
        XCTAssertEqual(useCase.getFormattedCacheSize(), "128 KB")

        try await useCase.clearCache()
        XCTAssertTrue(repo.clearCacheCalled)
    }

    func testFilterChannelsUseCase() {
        let useCase = DefaultFilterChannelsUseCase()

        let ch1 = Channel(id: "1", name: "Alpha", country: "US", categories: ["News"], isNSFW: false, logoURL: nil, hasStreams: true)
        let ch2 = Channel(id: "2", name: "Beta", country: "GB", categories: ["Sports"], isNSFW: false, logoURL: nil, hasStreams: false)
        let ch3 = Channel(id: "3", name: "Gamma", country: "US", categories: ["Music"], isNSFW: false, logoURL: nil, hasStreams: true)

        let channels = [ch1, ch2, ch3]

        // 1. Group by country
        let groupedByCountry = useCase.execute(
            channels: channels,
            query: "",
            categories: [],
            countries: [],
            scope: .all,
            favorites: [],
            hideUnavailableStreams: false,
            grouping: .country,
            sectionSort: .ascending,
            channelSort: .ascending
        )

        XCTAssertEqual(groupedByCountry.count, 2)

        // 2. Filter by search query
        let searchResult = useCase.execute(
            channels: channels,
            query: "alpha",
            categories: [],
            countries: [],
            scope: .all,
            favorites: [],
            hideUnavailableStreams: false,
            grouping: .name,
            sectionSort: .ascending,
            channelSort: .ascending
        )
        let alphaList = searchResult.flatMap(\.1)
        XCTAssertEqual(alphaList.count, 1)
        XCTAssertEqual(alphaList.first?.name, "Alpha")

        // 3. Filter by hideUnavailableStreams
        let availableResult = useCase.execute(
            channels: channels,
            query: "",
            categories: [],
            countries: [],
            scope: .all,
            favorites: [],
            hideUnavailableStreams: true,
            grouping: .name,
            sectionSort: .ascending,
            channelSort: .ascending
        )
        let availableList = availableResult.flatMap(\.1)
        XCTAssertEqual(availableList.count, 2)
        XCTAssertFalse(availableList.contains { $0.id == "2" })

        // 4. Filter by scope favorites
        let favoritesResult = useCase.execute(
            channels: channels,
            query: "",
            categories: [],
            countries: [],
            scope: .favorites,
            favorites: ["3"],
            hideUnavailableStreams: false,
            grouping: .name,
            sectionSort: .ascending,
            channelSort: .ascending
        )
        let favList = favoritesResult.flatMap(\.1)
        XCTAssertEqual(favList.count, 1)
        XCTAssertEqual(favList.first?.id, "3")
    }
}
