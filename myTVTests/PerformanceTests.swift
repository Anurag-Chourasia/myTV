//
//  PerformanceTests.swift
//  myTVTests
//
//  Created by Anurag Chourasia on 03/11/26.
//

import XCTest
@testable import myTV

final class PerformanceTests: XCTestCase {

    func testM3UPlaylistParsingThroughput() {
        var playlist = "#EXTM3U\n"
        for index in 0..<1000 {
            playlist += "#EXTINF:-1 tvg-id=\"chan.\(index)\" tvg-name=\"Channel \(index)\" group-title=\"Category \(index % 10)\" ,Channel \(index)\n"
            playlist += "http://stream.example.com/live/\(index).m3u8\n"
        }
        let data = Data(playlist.utf8)
        let parser = M3UParser()

        measure {
            let channels = parser.parse(data)
            XCTAssertEqual(channels.count, 1000)
        }
    }

    func testChannelDiskCacheThroughput() {
        let cache = ChannelDiskCache()
        let channels = (0..<200).map { index in
            ChannelDTO(
                id: "perf-chan-\(index)",
                name: "Perf Channel \(index)",
                alt_names: [],
                network: nil,
                owners: [],
                country: "US",
                categories: ["news", "sports"],
                is_nsfw: false,
                launched: nil,
                closed: nil,
                replaced_by: nil,
                website: nil
            )
        }

        measure {
            cache.save(channels)
            let loaded = cache.load()
            XCTAssertEqual(loaded?.count, 200)
        }

        cache.clear()
    }

    func testFavoriteStoreQueryThroughput() throws {
        let suite = "mytv-perf-tests-" + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        let store = FavoriteChannelStore(defaults: defaults)
        let favoriteSet = Set((0..<500).map { "fav.channel.\($0)" })
        store.save(favoriteSet)

        measure {
            let loaded = store.load()
            XCTAssertEqual(loaded.count, 500)
        }
    }
}
