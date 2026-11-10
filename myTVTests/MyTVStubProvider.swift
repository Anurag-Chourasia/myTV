import Foundation
@testable import myTV

/// Provides structured stub data loaded from the AppStubData submodule for myTV.
struct MyTVStubProvider {

    enum Scenario: String, CaseIterable { case positive, empty, negative }

    private final class BundleMarker {}

    static func developerCatalogData() throws -> Data {
        #if SWIFT_PACKAGE
        let bundle = Bundle.module
        let directory: String? = nil
        #else
        let bundle = Bundle(for: BundleMarker.self)
        let directory: String? = "DeveloperFixtures"
        #endif
        if let file = bundle.url(forResource: "mytv-developer-catalog", withExtension: "json", subdirectory: directory) {
            return try Data(contentsOf: file)
        }
        if let file = Bundle.main.url(forResource: "mytv-developer-catalog", withExtension: "json", subdirectory: "DeveloperFixtures") {
            return try Data(contentsOf: file)
        }
        throw CocoaError(.fileNoSuchFile)
    }

    static func makeStubRepository(scenario: String = "success") -> any ChannelRepository {
        DeveloperStubRepository(scenario: scenario)
    }
}
