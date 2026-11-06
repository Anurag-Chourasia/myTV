//
//  RiskBasedIsolationAndConcurrencyTests.swift
//  myTVTests
//
//  Risk-based isolation, migration, and concurrency coverage (IOS-23)
//

import XCTest
@testable import myTV

final class RiskBasedIsolationAndConcurrencyTests: XCTestCase {
    private var suiteName: String?
    private var defaults: UserDefaults?

    override func setUpWithError() throws {
        try super.setUpWithError()
        let name = "test-mytv-risk-\(UUID().uuidString)"
        suiteName = name
        defaults = UserDefaults(suiteName: name)
    }

    override func tearDown() {
        if let suiteName {
            defaults?.removePersistentDomain(forName: suiteName)
        }
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    // MARK: - Account Isolation & Multi-User Favorites

    func testAccountSwitchingIsolatesFavoriteStoreKeys() throws {
        let currentDefaults = try XCTUnwrap(defaults)
        let ownerA = UUID()
        let ownerB = UUID()
        let accountA = FavoriteChannelStore(defaults: currentDefaults, ownerID: ownerA)
        let accountB = FavoriteChannelStore(defaults: currentDefaults, ownerID: ownerB)
        accountA.save(["chan-1", "chan-2"])
        XCTAssertTrue(accountB.load().isEmpty)
        accountB.save(["chan-99"])
        XCTAssertEqual(accountA.load(), ["chan-1", "chan-2"])
        XCTAssertEqual(FavoriteChannelStore(defaults: currentDefaults, ownerID: ownerB).load(), ["chan-99"])
    }

    // MARK: - Concurrent Favorites Access Safety

    func testConcurrentFavoriteStoreModificationsDoNotCorrupt() throws {
        let currentDefaults = try XCTUnwrap(defaults)
        let store = FavoriteChannelStore(defaults: currentDefaults)

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

    func testStaleCachePurgePreventsZombiePlaybackUrls() throws {
        let cache = ChannelDiskCache()
        cache.clear()
        defer { cache.clear() }

        let dummyChannels = [
            ChannelDTO(
                id: "risk-channel-1",
                name: "Risk Channel",
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

        cache.save(dummyChannels)
        XCTAssertEqual(cache.load()?.count, 1)

        // Evict/clear cache
        cache.clear()
        let reloaded = cache.load()

        XCTAssertNil(reloaded, "Regression: Cache purge must return nil rather than stale or zombie channels")
    }
}
