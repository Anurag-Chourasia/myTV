import XCTest
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

        let loaded = cache.load()
        XCTAssertNotNil(loaded, "Cache load should return saved channels")
        XCTAssertEqual(loaded?.count, 2)
        XCTAssertEqual(loaded?[0].id, "cache-1")
        XCTAssertEqual(loaded?[1].name, "Channel Two")

        cache.clear()
        XCTAssertNil(cache.load(), "Cache load should return nil after clear")
    }
}
