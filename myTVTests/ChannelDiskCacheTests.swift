import XCTest
import FoundationKit
@testable import myTV

final class ChannelDiskCacheTests: XCTestCase {

    func testSaveLoadAndClearDiskCache() {
        let cache = ChannelDiskCache()
        cache.clear()

        let dummyChannels = [
            ChannelDTO(
                id: "cache-1",
                name: "Channel One",
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
                id: "cache-2",
                name: "Channel Two",
                alt_names: [],
                network: nil,
                owners: [],
                country: "CA",
                categories: ["sports"],
                is_nsfw: false,
                launched: nil,
                closed: nil,
                replaced_by: nil,
                website: nil
            )
        ]

        cache.save(dummyChannels)

        XCTAssertEqual(cache.entryCount, 2)
        XCTAssertGreaterThan(cache.fileSizeBytes, 0)

        let loaded = cache.load()
        XCTAssertNotNil(loaded, "Cache load should return saved channels")
        XCTAssertEqual(loaded?.count, 2)
        XCTAssertEqual(loaded?[0].id, "cache-1")
        XCTAssertEqual(loaded?[1].name, "Channel Two")

        cache.clear()
        XCTAssertNil(cache.load(), "Cache load should return nil after clear")
        XCTAssertEqual(cache.entryCount, 0)
        XCTAssertEqual(cache.formattedFileSize, "0 KB")
    }

    func testChannelRepositorySavesToDiskCacheOnSuccessfulFetch() async throws {
        let cache = ChannelDiskCache()
        cache.clear()
        defer { cache.clear() }

        let api = MockCacheAPIService()
        let repo = ChannelRepositoryImpl(api: api, cache: cache)

        let channels = try await repo.fetchChannels()
        XCTAssertEqual(channels.count, 2)

        let cached = cache.load()
        XCTAssertNotNil(cached, "Cache must be populated after successful network fetch")
        XCTAssertEqual(cached?.count, 2)
        XCTAssertEqual(cached?[0].id, "mock-1")
    }

    func testChannelRepositoryUsesDiskCacheWhenNetworkFails() async throws {
        let cache = ChannelDiskCache()
        cache.clear()
        defer { cache.clear() }

        let dummyChannels = [
            ChannelDTO(
                id: "offline-1",
                name: "Offline Channel",
                alt_names: [],
                network: nil,
                owners: [],
                country: "US",
                categories: ["offline"],
                is_nsfw: false,
                launched: nil,
                closed: nil,
                replaced_by: nil,
                website: nil
            )
        ]
        cache.save(dummyChannels)

        let failingApi = MockCacheAPIService(shouldFail: true)
        let repo = ChannelRepositoryImpl(api: failingApi, cache: cache)

        let channels = try await repo.fetchChannels()
        XCTAssertEqual(channels.count, 1, "Must return cached channels when offline")
        XCTAssertEqual(channels[0].id, "offline-1")
        XCTAssertEqual(channels[0].name, "Offline Channel")
    }

    func testInjectedFoundationKitDependencies() {
        let testDir = FileManager.default.temporaryDirectory.appendingPathComponent("test_cache_\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: testDir) }

        let customFormatter = ByteCountFormatterFactory.make(zeroSizeString: "Empty")
        let customClock = FixedClock(now: Date(timeIntervalSince1970: 1000))
        let cache = ChannelDiskCache(
            fileURL: testDir,
            byteFormatter: customFormatter,
            clock: customClock
        )

        XCTAssertEqual(cache.formattedFileSize, "Empty")
        XCTAssertEqual(customClock.now.timeIntervalSince1970, 1000)
    }
}

private final class MockCacheAPIService: IPTVAPIService {
    let shouldFail: Bool

    init(shouldFail: Bool = false) {
        self.shouldFail = shouldFail
    }

    func fetchChannels() async throws -> [ChannelDTO] {
        if shouldFail { throw URLError(.notConnectedToInternet) }
        return [
            ChannelDTO(id: "mock-1", name: "Mock 1", alt_names: [], network: nil, owners: [], country: "IN", categories: [], is_nsfw: false, launched: nil, closed: nil, replaced_by: nil, website: nil),
            ChannelDTO(id: "mock-2", name: "Mock 2", alt_names: [], network: nil, owners: [], country: "IN", categories: [], is_nsfw: false, launched: nil, closed: nil, replaced_by: nil, website: nil)
        ]
    }

    func fetchLogos() async throws -> [LogoDTO] { [] }
    func fetchCategoryPlaylist(_ id: String) async throws -> [M3UChannel] { [] }
    func fetchStreams() async throws -> [StreamDTO] { [] }
}
