import XCTest
import UIKit
@testable import myTV

@MainActor
final class AppRuntimeTests: XCTestCase {

    func testBrandColorsStayOpaqueInBothAppearances() throws {
        let names = ["BrandBackground", "BrandSurface", "BrandAction",
                     "AuthBackground", "AuthForeground", "AuthAction", "AuthOnAction"]
        for style in [UIUserInterfaceStyle.light, .dark] {
            let traits = UITraitCollection(userInterfaceStyle: style)
            for name in names {
                let color = try XCTUnwrap(UIColor(named: name, in: .main, compatibleWith: traits))
                XCTAssertEqual(color.resolvedColor(with: traits).cgColor.alpha, 1, accuracy: 0.001,
                               "\(name) must remain opaque")
            }
        }
    }

    func testSettingsPolicyAndFixtures() async throws {
        let defaults = UserDefaults.standard
        let keys = ["authentication", "source", "scenario", "haptics", "logoPreview", "version", "build"]
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

        defaults.removeObject(forKey: "developer.authentication")
        XCTAssertFalse(AppRuntime.authenticationEnabled)
        defaults.set(true, forKey: "developer.authentication")
        #if DEBUG
        XCTAssertTrue(AppRuntime.authenticationEnabled)
        #else
        XCTAssertFalse(AppRuntime.authenticationEnabled)
        #endif

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

        let showcase = DeveloperStubRepository(scenario: "showcase")
        let showcaseChannels = try await showcase.fetchChannels()
        XCTAssertEqual(showcaseChannels.count, 8)
        XCTAssertTrue(showcaseChannels.allSatisfy { $0.hasStreams == true })

        let showcaseStreams = try await showcase.fetchStreams(channelId: showcaseChannels[0].id)
        XCTAssertEqual(showcaseStreams.count, 2)
        XCTAssertTrue(showcaseStreams[0].url.hasPrefix("https://"))

        defaults.set("showcase", forKey: "developer.scenario")
        XCTAssertEqual(AppRuntime.stubScenario, "showcase")
        XCTAssertTrue(AppRuntime.isShowcaseMode)

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
    #if DEBUG
    func testMalformedSharedCatalogReportsFailure() async {
        let repository = DeveloperStubRepository(scenario: "success", loadData: { Data("invalid".utf8) })
        do {
            _ = try await repository.fetchChannels()
            XCTFail("Malformed shared fixture must fail decoding")
        } catch {
            XCTAssertTrue(error is DecodingError)
        }
    }
    #endif

}
