import XCTest
@testable import myTV

@MainActor
final class FavoriteChannelStoreTests: XCTestCase {

    func testFreshStoreRestoresStableIDsAndRemoval() async throws {
        let suite = "mytv-favorites-tests-" + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        let store = FavoriteChannelStore(defaults: defaults)
        XCTAssertTrue(store.load().isEmpty)

        store.save(["News.in", "Movies.us"])
        let reopened = FavoriteChannelStore(defaults: try XCTUnwrap(UserDefaults(suiteName: suite)))
        XCTAssertEqual(reopened.load(), ["News.in", "Movies.us"])

        var ids = reopened.load()
        ids.remove("News.in")
        reopened.save(ids)
        XCTAssertEqual(FavoriteChannelStore(defaults: defaults).load(), ["Movies.us"])

        reopened.save([])
        XCTAssertTrue(FavoriteChannelStore(defaults: defaults).load().isEmpty)
    }

    func testCorruptPreferenceDoesNotCrashOrPolluteOtherPreferences() async throws {
        let suite = "mytv-favorites-tests-" + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        defaults.set(42, forKey: "favoriteChannelIDs")
        defaults.set("dark", forKey: "appAppearance")

        let store = FavoriteChannelStore(defaults: defaults)
        XCTAssertTrue(store.load().isEmpty)

        store.save(["News.in"])
        XCTAssertEqual(store.load(), ["News.in"])
        XCTAssertEqual(defaults.string(forKey: "appAppearance"), "dark")
    }
    func testLegacyClaimSurvivesRelaunchAndDoesNotLeakAfterSignOutOrSwitch() throws {
        let suite = "mytv-owner-tests-" + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(["legacy"], forKey: "favoriteChannelIDs")
        let ownerA = UUID()
        let accountA = FavoriteChannelStore(defaults: defaults, ownerID: ownerA)
        XCTAssertEqual(accountA.load(), ["legacy"])
        XCTAssertEqual(defaults.stringArray(forKey: "favoriteChannelIDs"), ["legacy"])
        XCTAssertTrue(FavoriteChannelStore(defaults: defaults).load().isEmpty)
        let accountB = FavoriteChannelStore(defaults: defaults, ownerID: UUID())
        XCTAssertTrue(accountB.load().isEmpty)
        accountB.save(["B-only"])
        XCTAssertEqual(FavoriteChannelStore(defaults: defaults, ownerID: ownerA).load(), ["legacy"])
        accountA.save([])
        XCTAssertTrue(FavoriteChannelStore(defaults: defaults, ownerID: ownerA).load().isEmpty)
        XCTAssertEqual(accountB.load(), ["B-only"])
    }

    func testAnonymousEditsAndUnreadableEnvelopeArePreserved() throws {
        let suite = "mytv-owner-tests-" + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(["legacy"], forKey: "favoriteChannelIDs")
        let guest = FavoriteChannelStore(defaults: defaults)
        guest.save(["guest-edit"])
        let account = FavoriteChannelStore(defaults: defaults, ownerID: UUID())
        XCTAssertEqual(account.load(), ["guest-edit"])
        guest.save(["new-guest"])
        XCTAssertEqual(account.load(), ["guest-edit"])
        defaults.set(Data([1, 2, 3]), forKey: "favoriteChannelIDs.owners.v1")
        account.save([])
        XCTAssertEqual(defaults.data(forKey: "favoriteChannelIDs.owners.v1"), Data([1, 2, 3]))
    }

}
