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
}
