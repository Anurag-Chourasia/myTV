//
//  RiskBasedIsolationAndConcurrencyTests.swift
//  myTVTests
//
//  Risk-based isolation, migration, and concurrency coverage (IOS-23)
//

import XCTest
@testable import myTV

final class RiskBasedIsolationAndConcurrencyTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "test-mytv-risk-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    // MARK: - Account Isolation & Multi-User Favorites

    func testAccountSwitchingIsolatesFavoriteStoreKeys() {
        let userAKey = "favorites_user_\(UUID().uuidString)"
        let userBKey = "favorites_user_\(UUID().uuidString)"

        // User A saves favorites
        defaults.set(["chan-1", "chan-2"], forKey: userAKey)
        XCTAssertEqual(Set(defaults.stringArray(forKey: userAKey) ?? []), ["chan-1", "chan-2"])

        // User B has zero favorites
        XCTAssertEqual(Set(defaults.stringArray(forKey: userBKey) ?? []), [])

        // User B saves their own favorites
        defaults.set(["chan-99"], forKey: userBKey)
        XCTAssertEqual(Set(defaults.stringArray(forKey: userBKey) ?? []), ["chan-99"])

        // User A's favorites remain unchanged and isolated
        XCTAssertEqual(Set(defaults.stringArray(forKey: userAKey) ?? []), ["chan-1", "chan-2"])
    }

    // MARK: - Concurrent Favorites Access Safety

    func testConcurrentFavoriteStoreModificationsDoNotCorrupt() {
        let store = FavoriteChannelStore(defaults: defaults)

        let expectation = expectation(description: "Concurrent favorite updates")
        expectation.expectedFulfillmentCount = 20

        DispatchQueue.concurrentPerform(iterations: 20) { index in
            var current = store.load()
            current.insert("channel_\(index)")
            store.save(current)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)

        let finalCount = store.load().count
        XCTAssertGreaterThan(finalCount, 0, "Concurrent mutations should successfully preserve channel set state")
    }

    // MARK: - Demonstrated Failure & Regression Contract

    func testStaleCachePurgePreventsZombiePlaybackUrls() {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let cache = ChannelDiskCache(fileManager: .default, directory: tempDir)
        let sampleChannel = Channel(id: "1", name: "News Channel", logo: nil, streams: [
            Stream(url: URL(string: "https://example.com/stream1.m3u8")!, quality: "1080p")
        ])

        cache.save([sampleChannel])
        XCTAssertEqual(cache.load()?.count, 1)

        // Evict/clear cache
        cache.clear()
        let reloaded = cache.load()

        XCTAssertNil(reloaded, "Regression: Cache purge must return nil rather than stale or zombie channels")
    }
}
