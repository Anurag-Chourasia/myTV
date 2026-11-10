import XCTest
@testable import myTV

private final class MockIPTVAPIService: IPTVAPIService, @unchecked Sendable {
    var streamRequests = 0
    var streams: [StreamDTO] = []
    var logos: [LogoDTO] = []
    var error: Error?
    var channelsError: Error?

    func fetchChannels() async throws -> [ChannelDTO] {
        if let channelsError { throw channelsError }
        let json = #"[{"id":"A.in","name":"A","alt_names":[],"owners":[],"country":"IN","categories":[],"is_nsfw":false},{"id":"B.in","name":"B","alt_names":[],"owners":[],"country":"IN","categories":[],"is_nsfw":false}]"#
        return try JSONDecoder().decode([ChannelDTO].self, from: Data(json.utf8))
    }

    func fetchLogos() async throws -> [LogoDTO] { logos }

    func fetchCategoryPlaylist(_ id: String) async throws -> [M3UChannel] { [] }

    func fetchStreams() async throws -> [StreamDTO] {
        streamRequests += 1
        if let error { throw error }
        return streams
    }
}

private final class MockHTTPClient: HTTPClient, @unchecked Sendable {
    var dataToReturn: Data = Data()
    var rawDataToReturn: Data = Data()
    var requestedURLs: [URL] = []

    func get<T: Decodable>(_ url: URL) async throws -> T {
        requestedURLs.append(url)
        return try JSONDecoder().decode(T.self, from: dataToReturn)
    }

    func getRaw(_ url: URL) async throws -> Data {
        requestedURLs.append(url)
        return rawDataToReturn
    }
}

@MainActor
final class ChannelAvailabilityTests: XCTestCase {

    func testChannelsLoadAndMapCorrectly() async throws {
        let api = MockIPTVAPIService()
        api.streams = [
            StreamDTO(channel: "A.in", feed: nil, title: "Stream A", url: "https://fixture.invalid/streamA.m3u8", referrer: nil, user_agent: nil, quality: nil)
        ]
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let repo = ChannelRepositoryImpl(api: api, cache: ChannelDiskCache(fileURL: tempURL))
        let channels = try await repo.fetchChannels()

        XCTAssertEqual(channels.count, 2)
        XCTAssertEqual(channels[0].id, "A.in")
        XCTAssertEqual(channels[1].id, "B.in")
    }

    func testStreamsForChannelReturnsMatchingStreams() async throws {
        let api = MockIPTVAPIService()
        api.streams = [
            StreamDTO(channel: "A.in", feed: nil, title: "Stream 1", url: "https://fixture.invalid/stream1.m3u8", referrer: nil, user_agent: nil, quality: "1080p"),
            StreamDTO(channel: "B.in", feed: nil, title: "Stream 2", url: "https://fixture.invalid/stream2.m3u8", referrer: nil, user_agent: nil, quality: "720p")
        ]
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let repo = ChannelRepositoryImpl(api: api, cache: ChannelDiskCache(fileURL: tempURL))
        let streams = try await repo.fetchStreams(channelId: "A.in")

        XCTAssertEqual(streams.count, 1)
        XCTAssertEqual(streams[0].url, "https://fixture.invalid/stream1.m3u8")
    }

    func testChannelRepositoryOfflineFallbackAndStats() async throws {
        let api = MockIPTVAPIService()
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let cache = ChannelDiskCache(fileURL: tempURL)
        let repo = ChannelRepositoryImpl(api: api, cache: cache)

        // First successful fetch populates cache
        _ = try await repo.fetchChannels()
        XCTAssertGreaterThan(repo.cachedEntryCount, 0)
        XCTAssertFalse(repo.formattedCacheSize.isEmpty)

        // Network fails with offline error
        api.channelsError = URLError(.notConnectedToInternet)
        let offlineChannels = try await repo.fetchChannels()
        XCTAssertEqual(offlineChannels.count, 2)

        repo.clearCache()
        XCTAssertEqual(repo.cachedEntryCount, 0)
    }

    func testChannelRepositoryLogoRanking() async throws {
        let api = MockIPTVAPIService()
        api.logos = [
            LogoDTO(channel: "A.in", feed: nil, tags: [], width: 100, height: 100, format: .svg, url: "https://example.com/svg.svg"),
            LogoDTO(channel: "A.in", feed: nil, tags: [], width: 200, height: 200, format: .jpeg, url: "https://example.com/jpeg.jpg"),
            LogoDTO(channel: "A.in", feed: nil, tags: [], width: 50, height: 50, format: .png, url: "https://example.com/png.png")
        ]
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let repo = ChannelRepositoryImpl(api: api, cache: ChannelDiskCache(fileURL: tempURL))
        let channels = try await repo.fetchChannels()

        // PNG format has highest rank (3) so it should be picked despite smaller dimensions
        let channelA = channels.first { $0.id == "A.in" }
        XCTAssertEqual(channelA?.logoURL?.absoluteString, "https://example.com/png.png")
    }

    func testIPTVAPIServiceImplementation() async throws {
        let mockHTTP = MockHTTPClient()
        let service = IPTVAPIServiceImpl(client: mockHTTP)

        mockHTTP.dataToReturn = Data(#"[{"id":"c1","name":"C1","alt_names":[],"owners":[],"country":"US","categories":[],"is_nsfw":false}]"#.utf8)
        let channels = try await service.fetchChannels()
        XCTAssertEqual(channels.count, 1)

        mockHTTP.dataToReturn = Data(#"[{"channel":"c1","feed":null,"title":"T1","url":"https://stream.invalid/1","referrer":null,"user_agent":null,"quality":null}]"#.utf8)
        let streams = try await service.fetchStreams()
        XCTAssertEqual(streams.count, 1)

        mockHTTP.dataToReturn = Data(#"[{"channel":"c1","feed":null,"tags":[],"width":100,"height":100,"format":"PNG","url":"https://example.com/logo.png"}]"#.utf8)
        let logos = try await service.fetchLogos()
        XCTAssertEqual(logos.count, 1)

        mockHTTP.rawDataToReturn = Data("#EXTM3U\n#EXTINF:-1,Sample\nhttps://stream.invalid/sample.m3u8".utf8)
        let playlist = try await service.fetchCategoryPlaylist("news")
        XCTAssertEqual(playlist.count, 1)
    }
}
