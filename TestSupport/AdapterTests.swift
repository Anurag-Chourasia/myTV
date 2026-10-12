import Foundation
import XCTest
@testable import Adapter

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
            client?.urlProtocol(self, didFailWithError: URLError(.unsupportedURL)); return
        }
        let data: Data
        switch parts[1] {
        case "valid": data = Data(#"{"name":"fixture"}"#.utf8)
        case "empty": data = Data()
        case "invalid": data = Data("not json".utf8)
        case "playlist": data = Data("#EXTM3U\n#EXTINF:-1 tvg-id=\"Fixture.in\",Fixture Channel\nhttps://fixture.invalid/video\n".utf8)
        default: client?.urlProtocol(self, didFailWithError: URLError(.unsupportedURL)); return
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

final class AdapterTests: XCTestCase {
    struct Model: Decodable { let name: String }
    func url(_ path: String) -> URL { URL(string: "https://fixture.invalid/" + path)! }
    func session() -> URLSession {
        let c = URLSessionConfiguration.ephemeral; c.protocolClasses = [FixtureProtocol.self]
        return URLSession(configuration: c)
    }

    @MainActor func testTypedIgnoresStatusLikeLegacy() async throws {
        let s = session(); defer { s.invalidateAndCancel() }
        let current = CommonNetworkingHTTPClient(session: s)
        let old = URLSessionHTTPClient(session: s)
        for status in [200, 201, 401, 404, 500] {
            let a: Model = try await current.get(url("\(status)/valid"))
            let b: Model = try await old.get(url("\(status)/valid"))
            XCTAssertEqual(a.name, b.name)
        }
    }
    @MainActor func testRawPreservesPlaylistAndEmptyAtEveryStatus() async throws {
        let s = session(); defer { s.invalidateAndCancel() }
        let current = CommonNetworkingHTTPClient(session: s); let old = URLSessionHTTPClient(session: s)
        for status in [200, 204, 500] {
            for body in ["playlist", "empty"] {
                let a = try await current.getRaw(url("\(status)/\(body)"))
                let b = try await old.getRaw(url("\(status)/\(body)"))
                XCTAssertEqual(a, b)
            }
        }
    }
    @MainActor func testEmptyAndMalformedStillThrowDecodingErrorNotPackageError() async throws {
        let s = session(); defer { s.invalidateAndCancel() }
        let clients: [any HTTPClient] = [CommonNetworkingHTTPClient(session: s), URLSessionHTTPClient(session: s)]
        for client in clients {
            for path in ["204/empty", "200/invalid", "500/invalid", "500/empty"] {
                do { let _: Model = try await client.get(url(path)); XCTFail("Expected decoding failure") }
                catch is DecodingError {} catch { XCTFail("Wrong error: \(error)") }
            }
        }
    }
    @MainActor func testTransportAndCancellationErrorPresentationMatchesLegacy() async throws {
        let s = session(); defer { s.invalidateAndCancel() }
        let clients: [any HTTPClient] = [CommonNetworkingHTTPClient(session: s), URLSessionHTTPClient(session: s)]
        for path in ["offline", "cancelled"] {
            var messages: [String] = []
            for client in clients {
                for typed in [false, true] {
                    do {
                        if typed { let _: Model = try await client.get(url(path)) }
                        else { _ = try await client.getRaw(url(path)) }
                        XCTFail("Expected transport error")
                    } catch let error as URLError {
                        XCTAssertEqual(error.code, path == "cancelled" ? .cancelled : .notConnectedToInternet)
                        messages.append(error.localizedDescription)
                    } catch { XCTFail("Wrong error: \(error)") }
                }
            }
            XCTAssertEqual(messages.count, 4)
            XCTAssertEqual(Set(messages).count, 1)
        }
    }
    @MainActor func testTaskCancellationMatchesLegacyOnBothPaths() async throws {
        let s = session(); defer { s.invalidateAndCancel() }
        let clients: [any HTTPClient] = [CommonNetworkingHTTPClient(session: s), URLSessionHTTPClient(session: s)]
        // Each task is cancelled before awaiting to test cancellation at the URL-only adapter seam.
        for client in clients {
            for typed in [false, true] {
                let target = url("hold")
                let task = Task {
                    if typed { let _: Model = try await client.get(target) }
                    else { _ = try await client.getRaw(target) }
                }
                task.cancel()
                do { try await task.value; XCTFail("Expected cancellation") }
                catch let error as URLError { XCTAssertEqual(error.code, .cancelled) }
                catch { XCTFail("Wrong error: \(error)") }
            }
        }
    }
}
