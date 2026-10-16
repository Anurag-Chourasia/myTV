"""Compile the actual store with app isolation settings and test relaunch persistence."""
from pathlib import Path
import json
import shutil
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory(prefix='mytv-favorites-') as directory:
    package = Path(directory)
    (package / 'Sources/Favorites').mkdir(parents=True)
    (package / 'Tests/FavoritesTests').mkdir(parents=True)
    shutil.copy2(root / 'myTV/Data/Cache/FavoriteChannelStore.swift', package / 'Sources/Favorites/Store.swift')
    (package / 'Package.swift').write_text('''// swift-tools-version: 6.0
import PackageDescription
let package = Package(name: "Favorites", platforms: [.macOS(.v14)], targets: [
    .target(name: "Favorites", swiftSettings: [.unsafeFlags(["-default-isolation", "MainActor"])]),
    .testTarget(name: "FavoritesTests", dependencies: ["Favorites"])
])
''')
    (package / 'Tests/FavoritesTests/StoreTests.swift').write_text('''import XCTest
@testable import Favorites

@MainActor final class StoreTests: XCTestCase {
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
''')
    subprocess.run(['xcrun', 'swift', 'test', '--package-path', str(package), '--triple', 'arm64-apple-macosx14.0', '-Xswiftc', '-warnings-as-errors'], check=True)
