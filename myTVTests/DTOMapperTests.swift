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

    func testLogoDTODecodingAndEncodingFormats() throws {
        let jsonPng = Data(#"{"channel":"ch1","tags":[],"width":100,"height":100,"format":"PNG","url":"https://example.com/logo.png"}"#.utf8)
        let jsonJpg = Data(#"{"channel":"ch2","tags":[],"width":100,"height":100,"format":"JPG","url":"https://example.com/logo.jpg"}"#.utf8)
        let jsonJpeg = Data(#"{"channel":"ch3","tags":[],"width":100,"height":100,"format":"JPEG","url":"https://example.com/logo.jpeg"}"#.utf8)
        let jsonSvg = Data(#"{"channel":"ch4","tags":[],"width":100,"height":100,"format":"SVG","url":"https://example.com/logo.svg"}"#.utf8)
        let jsonOther = Data(#"{"channel":"ch5","tags":[],"width":100,"height":100,"format":"WEBP","url":"https://example.com/logo.webp"}"#.utf8)

        let dtoPng = try JSONDecoder().decode(LogoDTO.self, from: jsonPng)
        let dtoJpg = try JSONDecoder().decode(LogoDTO.self, from: jsonJpg)
        let dtoJpeg = try JSONDecoder().decode(LogoDTO.self, from: jsonJpeg)
        let dtoSvg = try JSONDecoder().decode(LogoDTO.self, from: jsonSvg)
        let dtoOther = try JSONDecoder().decode(LogoDTO.self, from: jsonOther)

        XCTAssertEqual(dtoPng.format, .png)
        XCTAssertEqual(dtoJpg.format, .jpeg)
        XCTAssertEqual(dtoJpeg.format, .jpeg)
        XCTAssertEqual(dtoSvg.format, .svg)
        XCTAssertEqual(dtoOther.format, .unknown("WEBP"))

        let encodedPng = try JSONEncoder().encode(dtoPng)
        let redecodedPng = try JSONDecoder().decode(LogoDTO.self, from: encodedPng)
        XCTAssertEqual(redecodedPng.format, .png)

        let encodedOther = try JSONEncoder().encode(dtoOther)
        let redecodedOther = try JSONDecoder().decode(LogoDTO.self, from: encodedOther)
        XCTAssertEqual(redecodedOther.format, .unknown("WEBP"))
    }

    func testIPTVEndpointCategory() {
        XCTAssertEqual(IPTVEndpoint.category("news"), "https://iptv-org.github.io/iptv/categories/news.m3u")
        XCTAssertFalse(IPTVEndpoint.allStreams.isEmpty)
        XCTAssertFalse(IPTVEndpoint.categoryIndex.isEmpty)
    }
}
