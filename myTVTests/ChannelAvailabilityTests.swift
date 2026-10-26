import XCTest
@testable import myTV

@MainActor
private final class MockIPTVAPIService: IPTVAPIService {
    var streamRequests = 0
    var streams: [StreamDTO] = []
    var error: Error?

    func fetchChannels() async throws -> [ChannelDTO] {
        let json = #"[{"id":"A.in","name":"A","alt_names":[],"owners":[],"country":"IN","categories":[],"is_nsfw":false},{"id":"B.in","name":"B","alt_names":[],"owners":[],"country":"IN","categories":[],"is_nsfw":false}]"#
        return try JSONDecoder().decode([ChannelDTO].self, from: Data(json.utf8))
    }

    func fetchLogos() async throws -> [LogoDTO] { [] }

    func fetchCategoryPlaylist(_ id: String) async throws -> [M3UChannel] { [] }

    func fetchStreams() async throws -> [StreamDTO] {
        streamRequests += 1
        if let error { throw error }
        return streams
    }
}

@MainActor
final class ChannelAvailabilityTests: XCTestCase {

    func testChannelsLoadAndMapCorrectly() async throws {
        let api = MockIPTVAPIService()
        api.streams = [
            StreamDTO(channel: "A.in", feed: nil, title: "Stream A", url: "https://fixture.invalid/streamA.m3u8", referrer: nil, user_agent: nil, quality: nil)
        ]
        let repo = ChannelRepositoryImpl(api: api, cache: ChannelDiskCache())
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
        let repo = ChannelRepositoryImpl(api: api, cache: ChannelDiskCache())
        let streams = try await repo.fetchStreams(channelId: "A.in")

        XCTAssertEqual(streams.count, 1)
        XCTAssertEqual(streams[0].url, "https://fixture.invalid/stream1.m3u8")
    }
}
