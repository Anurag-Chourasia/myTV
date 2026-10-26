import XCTest
@testable import myTV

@MainActor
final class DTOMapperTests: XCTestCase {

    func testChannelDTODecodingAndMappingToEntity() throws {
        let json = Data("""
        {
            "id": "france24.fr",
            "name": "France 24",
            "alt_names": ["F24"],
            "network": "France Medias Monde",
            "owners": ["French State"],
            "country": "FR",
            "categories": ["news", "international"],
            "is_nsfw": false,
            "launched": "2006-12-06",
            "closed": null,
            "replaced_by": null,
            "website": "https://www.france24.com"
        }
        """.utf8)

        let dto = try JSONDecoder().decode(ChannelDTO.self, from: json)
        XCTAssertEqual(dto.id, "france24.fr")
        XCTAssertEqual(dto.name, "France 24")
        XCTAssertEqual(dto.country, "FR")
        XCTAssertEqual(dto.categories, ["news", "international"])
        XCTAssertFalse(dto.is_nsfw)

        let logo = LogoDTO(
            channel: "france24.fr",
            feed: nil,
            tags: [],
            width: 512,
            height: 512,
            format: .png,
            url: "https://example.com/logo.png"
        )
        let logoURL = logo.url.flatMap(URL.init(string:))
        let channel = Channel(dto: dto, logoURL: logoURL)

        XCTAssertEqual(channel.id, "france24.fr")
        XCTAssertEqual(channel.name, "France 24")
        XCTAssertEqual(channel.country, "FR")
        XCTAssertEqual(channel.categories, ["news", "international"])
        XCTAssertEqual(channel.logoURL?.absoluteString, "https://example.com/logo.png")
    }

    func testStreamDTODecodingAndMappingToEntity() throws {
        let json = Data("""
        {
            "channel": "euronews.en",
            "feed": "primary",
            "title": "HD Stream",
            "url": "https://stream.euronews.com/live.m3u8",
            "referrer": "https://euronews.com",
            "user_agent": "Mozilla/5.0",
            "quality": "1080p"
        }
        """.utf8)

        let dto = try JSONDecoder().decode(StreamDTO.self, from: json)
        XCTAssertEqual(dto.channel, "euronews.en")
        XCTAssertEqual(dto.title, "HD Stream")
        XCTAssertEqual(dto.quality, "1080p")

        let stream = Stream(dto: dto)
        XCTAssertEqual(stream.title, "HD Stream")
        XCTAssertEqual(stream.url, "https://stream.euronews.com/live.m3u8")
        XCTAssertEqual(stream.quality, "1080p")
    }
}
