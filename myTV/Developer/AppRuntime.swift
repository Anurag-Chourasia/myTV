import Foundation

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
/// Selected at dependency construction; no real stream or image URLs are exposed.
final class DeveloperStubRepository: ChannelRepository {
    private let scenario: String
    init(scenario: String) { self.scenario = scenario }
    func fetchChannels() async throws -> [Channel] {
        if scenario == "offline" { throw URLError(.notConnectedToInternet) }
        if scenario == "empty" { return [] }
        if scenario == "showcase" {
            return [
                Channel(id: "bloomberg-quicktake", name: "Bloomberg Quicktake", country: "US", categories: ["news", "business"], isNSFW: false, logoURL: nil, hasStreams: true),
                Channel(id: "nasa-tv-hd", name: "NASA TV HD", country: "US", categories: ["science", "education"], isNSFW: false, logoURL: nil, hasStreams: true),
                Channel(id: "euronews-en", name: "Euronews English", country: "FR", categories: ["news"], isNSFW: false, logoURL: nil, hasStreams: true),
                Channel(id: "redbull-tv", name: "Red Bull TV", country: "AT", categories: ["sports"], isNSFW: false, logoURL: nil, hasStreams: true),
                Channel(id: "classic-cinema", name: "Classic Cinema Club", country: "GB", categories: ["movies"], isNSFW: false, logoURL: nil, hasStreams: true),
                Channel(id: "clubbing-tv", name: "Clubbing TV", country: "FR", categories: ["music"], isNSFW: false, logoURL: nil, hasStreams: true),
                Channel(id: "nature-documentary", name: "Wild Earth TV", country: "CA", categories: ["documentary", "science"], isNSFW: false, logoURL: nil, hasStreams: true),
                Channel(id: "retro-toons", name: "Retro Animation Network", country: "US", categories: ["animation", "kids"], isNSFW: false, logoURL: nil, hasStreams: true)
            ]
        }
        return [
            Channel(id: "debug-news", name: "Demo News", country: "IN", categories: ["news"], isNSFW: false, logoURL: nil, hasStreams: false),
            Channel(id: "debug-science", name: "Demo Science", country: "GB", categories: ["science"], isNSFW: false, logoURL: nil, hasStreams: false)
        ]
    }
    func fetchStreams(channelId: String) async throws -> [Stream] {
        if scenario == "offline" { throw URLError(.notConnectedToInternet) }
        if scenario == "empty" { return [] }
        if scenario == "showcase" {
            return [
                Stream(
                    id: "\(channelId)-1080p",
                    title: "Live HLS Feed (1080p / 16:9)",
                    url: "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8",
                    quality: "1080p"
                ),
                Stream(
                    id: "\(channelId)-720p",
                    title: "Backup HLS Feed (720p / 4:3)",
                    url: "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8",
                    quality: "720p"
                )
            ]
        }
        return []
    }
    func clearCache() {}
}
#endif
