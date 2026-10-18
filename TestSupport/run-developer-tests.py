"""Verify the actual runtime policy and offline fixtures in Debug and Release."""
from pathlib import Path
import shutil
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory(prefix="mytv-developer-") as directory:
    package = Path(directory)
    source = package / "Sources/Runtime"
    tests = package / "Tests/RuntimeTests"
    source.mkdir(parents=True)
    tests.mkdir(parents=True)
    for relative in ["Developer/AppRuntime.swift", "Core/Extensions/Bundle+AppInfo.swift",
                     "Domain/Entities/Channel.swift", "Domain/Entities/Stream.swift",
                     "Domain/Repositories/ChannelRepository.swift"]:
        shutil.copy2(root / "myTV" / relative, source / Path(relative).name)
    (package / "Package.swift").write_text('''// swift-tools-version: 6.0
import PackageDescription
let package = Package(name: "Runtime", platforms: [.macOS(.v14)], targets: [
    .target(name: "Runtime", swiftSettings: [.unsafeFlags(["-default-isolation", "MainActor"])]),
    .testTarget(name: "RuntimeTests", dependencies: ["Runtime"])
])
''')
    (tests / "RuntimeTests.swift").write_text('''import XCTest
@testable import Runtime

@MainActor final class RuntimeTests: XCTestCase {
    func testSettingsPolicyAndFixtures() async throws {
        let defaults = UserDefaults.standard
        let keys = ["source", "scenario", "haptics", "logoPreview", "version", "build"]
        let originals = keys.map { defaults.object(forKey: "developer." + $0) }
        defer { for (key, value) in zip(keys, originals) { defaults.set(value, forKey: "developer." + key) } }
        defaults.set("stub", forKey: "developer.source")
        defaults.set("success", forKey: "developer.scenario")
        defaults.set(false, forKey: "developer.haptics")
        defaults.set(false, forKey: "developer.logoPreview")
        defaults.set("99.9", forKey: "developer.version")
        defaults.set("999", forKey: "developer.build")
        #if DEBUG
        XCTAssertEqual(AppRuntime.stubScenario, "success")
        XCTAssertFalse(AppRuntime.hapticsEnabled)
        XCTAssertFalse(AppRuntime.logoPreviewEnabled)
        XCTAssertEqual(AppRuntime.version, "99.9")
        XCTAssertEqual(AppRuntime.build, "999")
        let success = DeveloperStubRepository(scenario: "success")
        let channels = try await success.fetchChannels()
        XCTAssertEqual(channels.count, 2)
        XCTAssertTrue(channels.allSatisfy { $0.logoURL == nil })
        let streams = try await success.fetchStreams(channelId: channels[0].id)
        XCTAssertTrue(streams.isEmpty)
        let empty = try await DeveloperStubRepository(scenario: "empty").fetchChannels()
        XCTAssertTrue(empty.isEmpty)
        do {
            _ = try await DeveloperStubRepository(scenario: "offline").fetchChannels()
            XCTFail("Offline must fail")
        } catch let error as URLError { XCTAssertEqual(error.code, .notConnectedToInternet) }
        defaults.set("invalid", forKey: "developer.scenario")
        XCTAssertEqual(AppRuntime.stubScenario, "success")
        defaults.set("live", forKey: "developer.source")
        XCTAssertNil(AppRuntime.stubScenario)
        #else
        XCTAssertNil(AppRuntime.stubScenario)
        XCTAssertTrue(AppRuntime.hapticsEnabled)
        XCTAssertTrue(AppRuntime.logoPreviewEnabled)
        XCTAssertEqual(AppRuntime.version, Bundle.main.appVersion)
        XCTAssertEqual(AppRuntime.build, Bundle.main.buildNumber)
        #endif
    }
}
''')
    for configuration in ["debug", "release"]:
        subprocess.run(["xcrun", "swift", "test", "--package-path", str(package),
                        "--configuration", configuration, "--triple", "arm64-apple-macosx14.0",
                        "-Xswiftc", "-warnings-as-errors"], check=True)
