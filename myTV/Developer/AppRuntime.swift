import Foundation
#if canImport(AuthKit)
import AuthKit
#endif

enum AppRuntime {
    /// New-feature rollout is off by default. Debug can opt in from launch settings;
    /// Release ignores developer preferences and uses only the bundled rollout flag.
    static var authenticationEnabled: Bool {
        #if DEBUG
        return UserDefaults.standard.bool(forKey: "developer.authentication")
        #else
        return Bundle.main.object(forInfoDictionaryKey: "AUTHKIT_ENABLED") as? Bool ?? false
        #endif
    }

    #if canImport(AuthKit)
    /// Current authentication environment (staging or production).
    /// Release strictly uses production; Debug allows opt-in developer staging testing.
    static var authEnvironment: AuthEnvironment {
        #if DEBUG
        let envString = UserDefaults.standard.string(forKey: "developer.authEnvironment") ?? "production"
        return AuthEnvironment(rawValue: envString) ?? .production
        #else
        return .production
        #endif
    }
    #endif

    static var hapticsEnabled: Bool { flag("haptics") }
    static var logoPreviewEnabled: Bool { flag("logoPreview") }
    static var version: String { override("version", fallback: Bundle.main.appVersion) }
    static var build: String { override("build", fallback: Bundle.main.buildNumber) }

    #if DEBUG
    /// Indicates whether the app was launched with the Showcase CLI argument or environment.
    static var isShowcaseLaunch: Bool {
        ProcessInfo.processInfo.arguments.contains("-Showcase") ||
        ProcessInfo.processInfo.arguments.contains("-ShowcaseMode") ||
        ProcessInfo.processInfo.environment["SHOWCASE_MODE"] == "1"
    }

    /// True when running in the curated credential-free Showcase experience.
    static var isShowcaseMode: Bool {
        if let scenario = stubScenario {
            return scenario == "showcase" || isShowcaseLaunch
        }
        return isShowcaseLaunch
    }
    #else
    static var isShowcaseLaunch: Bool { false }
    static var isShowcaseMode: Bool { false }
    #endif

    static var stubScenario: String? {
        #if DEBUG
        let source = UserDefaults.standard.string(forKey: "developer.source")
        if source == "live" { return nil }
        if source == "stub" {
            let scenario = UserDefaults.standard.string(forKey: "developer.scenario") ?? "success"
            return ["success", "showcase", "empty", "offline"].contains(scenario) ? scenario : "success"
        }
        if isShowcaseLaunch { return "showcase" }
        return nil
        #else
        return nil
        #endif
    }
    private static func flag(_ key: String) -> Bool {
        #if DEBUG
        return UserDefaults.standard.object(forKey: "developer." + key) as? Bool ?? true
        #else
        return true
        #endif
    }
    private static func override(_ key: String, fallback: String) -> String {
        #if DEBUG
        let value = UserDefaults.standard.string(forKey: "developer." + key)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? fallback : value
        #else
        return fallback
        #endif
    }
}

#if DEBUG
/// Preview and test repository backed by AppStubData shared fixtures (`mytv-developer-catalog.json`).
/// Selected at dependency construction; no real stream or image URLs are exposed.
final class DeveloperStubRepository: ChannelRepository {
    private let scenario: String
    private let loadData: () throws -> Data

    private struct Catalog: Decodable {
        struct ChannelFixture: Decodable {
            let id: String
            let name: String
            let country: String
            let categories: [String]
            let isNSFW: Bool
            let logoURL: URL?
            let hasStreams: Bool
            var channel: Channel {
                Channel(id: id, name: name, country: country, categories: categories,
                        isNSFW: isNSFW, logoURL: logoURL, hasStreams: hasStreams)
            }
        }
        struct StreamFixture: Decodable {
            let idSuffix: String
            let title: String
            let url: String
            let quality: String?
        }
        let success: [ChannelFixture]
        let showcase: [ChannelFixture]
        let showcaseStreams: [StreamFixture]
    }

    init(scenario: String, loadData: (() throws -> Data)? = nil) {
        self.scenario = scenario
        self.loadData = loadData ?? {
            #if SWIFT_PACKAGE
            let bundle = Bundle.module
            let directory: String? = nil
            #else
            let bundle = Bundle.main
            let directory: String? = "DeveloperFixtures"
            #endif
            guard let file = bundle.url(forResource: "mytv-developer-catalog", withExtension: "json", subdirectory: directory) else {
                throw URLError(.fileDoesNotExist)
            }
            return try Data(contentsOf: file)
        }
    }

    func fetchChannels() async throws -> [Channel] {
        if scenario == "offline" { throw URLError(.notConnectedToInternet) }
        if scenario == "empty" { return [] }
        let catalog = try JSONDecoder().decode(Catalog.self, from: loadData())
        return (scenario == "showcase" ? catalog.showcase : catalog.success).map(\.channel)
    }

    func fetchStreams(channelId: String) async throws -> [Stream] {
        if scenario == "offline" { throw URLError(.notConnectedToInternet) }
        guard scenario == "showcase" else { return [] }
        let catalog = try JSONDecoder().decode(Catalog.self, from: loadData())
        return catalog.showcaseStreams.map {
            Stream(id: channelId + $0.idSuffix, title: $0.title, url: $0.url, quality: $0.quality)
        }
    }
    func clearCache() {}
}
#endif
