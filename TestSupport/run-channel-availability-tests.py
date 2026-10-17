"""Test stream availability using the actual channel repository and models."""
from pathlib import Path
import json
import shutil
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory(prefix="mytv-availability-") as directory:
    package = Path(directory)
    source = package / "Sources/Catalog"
    tests = package / "Tests/CatalogTests"
    source.mkdir(parents=True)
    tests.mkdir(parents=True)
    for relative in ["Data/Repositories/ChannelRepositoryImpl.swift", "Domain/Repositories/ChannelRepository.swift",
                     "Domain/Entities/Channel.swift", "Domain/Entities/Stream.swift",
                     "Data/Network/DTO/ChannelDTO.swift", "Data/Network/DTO/StreamDTO.swift",
                     "Data/Network/DTO/LogoDTO.swift", "Data/Mappers/Stream+Mapper.swift",
                     "Data/Cache/ChannelCache.swift", "Data/Network/Parsers/M3UParser.swift"]:
        shutil.copy2(root / "myTV" / relative, source / Path(relative).name)
    api = (root / "myTV/Data/Network/Services/IPTVAPIService.swift").read_text()
    protocol = api[api.index("protocol IPTVAPIService"):api.index("final class IPTVAPIServiceImpl")]
    (source / "Support.swift").write_text(protocol + '''
// UI localization is irrelevant to these repository tests.
enum Localizable { enum App { enum Normalize { static let regex = "[^a-z0-9]" } } }
''')
    features = ["DisableOutwardActorInference", "InferSendableFromCaptures", "GlobalActorIsolatedTypesUsability",
                "MemberImportVisibility", "InferIsolatedConformances", "NonisolatedNonsendingByDefault"]
    flags = ["-default-isolation", "MainActor"] + [part for feature in features for part in ["-enable-upcoming-feature", feature]]
    (package / "Package.swift").write_text('''// swift-tools-version: 5.9
import PackageDescription
let package = Package(name: "Catalog", platforms: [.macOS(.v14)], targets: [
    .target(name: "Catalog", swiftSettings: [.unsafeFlags(FLAGS)]),
    .testTarget(name: "CatalogTests", dependencies: ["Catalog"])
], swiftLanguageVersions: [.v5])
'''.replace("FLAGS", json.dumps(flags)))
    (tests / "AvailabilityTests.swift").write_text('''import XCTest
@testable import Catalog

@MainActor final class API: IPTVAPIService {
    var streamRequests = 0
    var streams: [StreamDTO] = []
    var error: Error?
    func fetchChannels() async throws -> [ChannelDTO] {
        try JSONDecoder().decode([ChannelDTO].self, from: Data(#"[{"id":"A.in","name":"A","alt_names":[],"owners":[],"country":"IN","categories":[],"is_nsfw":false},{"id":"B.in","name":"B","alt_names":[],"owners":[],"country":"IN","categories":[],"is_nsfw":false}]"#.utf8))
    }
    func fetchLogos() async throws -> [LogoDTO] { [] }
    func fetchCategoryPlaylist(_ id: String) async throws -> [M3UChannel] { [] }
    func fetchStreams() async throws -> [StreamDTO] {
        streamRequests += 1
        if let error { throw error }
        return streams
    }
}
@MainActor final class Cache: ChannelCache {
    func save(_ channels: [ChannelDTO]) {}
    func load() -> [ChannelDTO]? { nil }
    func clear() {}
}
@MainActor final class AvailabilityTests: XCTestCase {
    func testSingleLookupMarksOnlyMissingChannels() async throws {
        let api = API()
        api.streams = [
            StreamDTO(channel: "A.in", feed: nil, title: "A", url: "https://example.com/a.m3u8", referrer: nil, user_agent: nil, quality: nil),
            StreamDTO(channel: nil, feed: nil, title: "Unassigned", url: "https://example.com/other.m3u8", referrer: nil, user_agent: nil, quality: nil)
        ]
        let result = try await ChannelRepositoryImpl(api: api, cache: Cache()).fetchChannels()
        XCTAssertEqual(result.map(\\.hasStreams), [true, false])
        XCTAssertEqual(api.streamRequests, 1)
    }
    func testEmptyDirectoryMarksAllChannelsUnavailable() async throws {
        let result = try await ChannelRepositoryImpl(api: API(), cache: Cache()).fetchChannels()
        XCTAssertEqual(result.map(\\.hasStreams), [false, false])
    }
    func testFailureKeepsCatalogWithoutFalseUnavailableLabels() async throws {
        let api = API(); api.error = URLError(.notConnectedToInternet)
        let result = try await ChannelRepositoryImpl(api: api, cache: Cache()).fetchChannels()
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.allSatisfy { $0.hasStreams == nil })
    }
    func testCancellationIsNotConvertedToUnknown() async throws {
        let api = API(); api.error = URLError(.cancelled)
        do {
            _ = try await ChannelRepositoryImpl(api: api, cache: Cache()).fetchChannels()
            XCTFail("Expected cancellation")
        } catch { XCTAssertTrue(error is CancellationError) }
    }
}
''')
    subprocess.run(["xcrun", "swift", "test", "--package-path", str(package),
                    "--triple", "arm64-apple-macosx14.0", "-Xswiftc", "-warnings-as-errors"], check=True)
