import Foundation
import XCTest
@testable import myTV

private final class URLSessionLegacyClient: HTTPClient {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func get<T: Decodable>(_ url: URL) async throws -> T {
        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode(T.self, from: data)
    }

    func getRaw(_ url: URL) async throws -> Data {
        let (data, _) = try await session.data(from: url)
        return data
    }
}

private final class FixtureProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let path = request.url!.path
        if path == "/hold" {
            (Self.property(forKey: "started", in: request) as? XCTestExpectation)?.fulfill()
            return
        }
        if path == "/cancelled" || path == "/offline" {
            client?.urlProtocol(self, didFailWithError: URLError(path == "/cancelled" ? .cancelled : .notConnectedToInternet))
            return
        }
        let parts = path.split(separator: "/")
        guard parts.count == 2, let status = Int(parts[0]) else {
            client?.urlProtocol(self, didFailWithError: URLError(.unsupportedURL))
            return
        }
        let data: Data
        switch parts[1] {
        case "valid":
            data = Data(#"{"name":"fixture"}"#.utf8)
        case "empty":
            data = Data()
        case "invalid":
            data = Data("not json".utf8)
        case "playlist":
            data = Data("#EXTM3U\n#EXTINF:-1 tvg-id=\"Fixture.in\",Fixture Channel\nhttps://fixture.invalid/video\n".utf8)
        default:
            client?.urlProtocol(self, didFailWithError: URLError(.unsupportedURL))
            return
        }
        let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {
        (Self.property(forKey: "stopped", in: request) as? XCTestExpectation)?.fulfill()
    }
}

final class HTTPAdapterTests: XCTestCase {
    struct Model: Decodable { let name: String }

    func url(_ path: String) -> URL { URL(string: "https://fixture.invalid/" + path)! }

    func session() -> URLSession {
        let c = URLSessionConfiguration.ephemeral
        c.protocolClasses = [FixtureProtocol.self]
        return URLSession(configuration: c)
    }

    @MainActor
    func testTypedIgnoresStatusLikeLegacy() async throws {
        let s = session()
        defer { s.invalidateAndCancel() }
        let current = CommonNetworkingHTTPClient(session: s)
        let old = URLSessionLegacyClient(session: s)
        for status in [200, 201, 401, 404, 500] {
            let a: Model = try await current.get(url("\(status)/valid"))
            let b: Model = try await old.get(url("\(status)/valid"))
            XCTAssertEqual(a.name, b.name)
        }
    }

    @MainActor
    func testRawPreservesPlaylistAndEmptyAtEveryStatus() async throws {
        let s = session()
        defer { s.invalidateAndCancel() }
        let current = CommonNetworkingHTTPClient(session: s)
        let old = URLSessionLegacyClient(session: s)
        for status in [200, 304, 403, 502] {
            let a = try await current.getRaw(url("\(status)/playlist"))
            let b = try await old.getRaw(url("\(status)/playlist"))
            XCTAssertEqual(a, b)
            let ea = try await current.getRaw(url("\(status)/empty"))
            let eb = try await old.getRaw(url("\(status)/empty"))
            XCTAssertEqual(ea, eb)
        }
    }

    @MainActor
    func testCancellation() async throws {
        let s = session()
        defer { s.invalidateAndCancel() }
        let client = CommonNetworkingHTTPClient(session: s)
        do {
            let _: Model = try await client.get(url("cancelled"))
            XCTFail("Should throw cancellation error")
        } catch let error as URLError {
            XCTAssertEqual(error.code, .cancelled)
        }
    }

    @MainActor
    func testOfflineError() async throws {
        let s = session()
        defer { s.invalidateAndCancel() }
        let client = CommonNetworkingHTTPClient(session: s)
        do {
            let _: Model = try await client.get(url("offline"))
            XCTFail("Should throw offline error")
        } catch let error as URLError {
            XCTAssertEqual(error.code, .notConnectedToInternet)
        }
    }
}
