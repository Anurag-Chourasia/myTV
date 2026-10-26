import XCTest
@testable import myTV

@MainActor
final class AppRuntimeTests: XCTestCase {

    func testSettingsPolicyAndFixtures() async throws {
        let defaults = UserDefaults.standard
        let keys = ["source", "scenario", "haptics", "logoPreview", "version", "build"]
        let originals = keys.map { defaults.object(forKey: "developer." + $0) }
        defer {
            for (key, value) in zip(keys, originals) {
                if let value {
                    defaults.set(value, forKey: "developer." + key)
                } else {
                    defaults.removeObject(forKey: "developer." + key)
                }
            }
        }

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
        } catch let error as URLError {
            XCTAssertEqual(error.code, .notConnectedToInternet)
        }

        defaults.set("invalid", forKey: "developer.scenario")
        XCTAssertEqual(AppRuntime.stubScenario, "success")
        #endif
    }
}
