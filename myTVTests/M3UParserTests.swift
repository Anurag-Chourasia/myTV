import XCTest
@testable import myTV

final class M3UParserTests: XCTestCase {

    func testParseStandardM3UPlaylist() {
        let playlist = """
        #EXTM3U
        #EXTINF:-1 tvg-id="cnn.us" tvg-name="CNN" group-title="News" ,CNN USA
        http://example.com/cnn/live.m3u8
        #EXTINF:-1 tvg-id="bbc.uk" tvg-name="BBC" group-title="News" ,BBC News
        http://example.com/bbc/live.m3u8
        """

        let data = Data(playlist.utf8)
        let parser = M3UParser()
        let channels = parser.parse(data)

        XCTAssertEqual(channels.count, 2)

        XCTAssertEqual(channels[0].name, "CNN USA")
        XCTAssertEqual(channels[0].url, "http://example.com/cnn/live.m3u8")
        XCTAssertEqual(channels[0].attributes["tvg-id"], "cnn.us")
        XCTAssertEqual(channels[0].attributes["group-title"], "News")

        XCTAssertEqual(channels[1].name, "BBC News")
        XCTAssertEqual(channels[1].url, "http://example.com/bbc/live.m3u8")
        XCTAssertEqual(channels[1].attributes["tvg-id"], "bbc.uk")
    }

    func testParseEmptyOrMalformedDataReturnsEmptyList() {
        let parser = M3UParser()
        let empty = parser.parse(Data())
        XCTAssertTrue(empty.isEmpty)

        let gibberish = Data("Just some random text\nwithout tags".utf8)
        let result = parser.parse(gibberish)
        XCTAssertTrue(result.isEmpty)
    }
}
