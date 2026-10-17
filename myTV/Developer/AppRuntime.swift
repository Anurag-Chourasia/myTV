import Foundation

enum AppRuntime {
    static var hapticsEnabled: Bool { flag("haptics") }
    static var logoPreviewEnabled: Bool { flag("logoPreview") }
    static var version: String { override("version", fallback: Bundle.main.appVersion) }
    static var build: String { override("build", fallback: Bundle.main.buildNumber) }
    static var stubScenario: String? {
        #if DEBUG
        guard UserDefaults.standard.string(forKey: "developer.source") == "stub" else { return nil }
        let scenario = UserDefaults.standard.string(forKey: "developer.scenario") ?? "success"
        return ["success", "empty", "offline"].contains(scenario) ? scenario : "success"
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
        return [
            Channel(id: "debug-news", name: "Demo News", country: "IN", categories: ["news"], isNSFW: false, logoURL: nil),
            Channel(id: "debug-science", name: "Demo Science", country: "GB", categories: ["science"], isNSFW: false, logoURL: nil)
        ]
    }
    func fetchStreams(channelId: String) async throws -> [Stream] {
        if scenario == "offline" { throw URLError(.notConnectedToInternet) }
        return []
    }
    func clearCache() {}
}
#endif
