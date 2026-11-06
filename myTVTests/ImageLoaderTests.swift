import XCTest
import UIKit
@testable import myTV

private final class ImageTestURLProtocol: URLProtocol {
    static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = ImageTestURLProtocol.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

private final class TestImageCache: ImageCache {
    private var storage: [String: UIImage] = [:]
    var clearCallCount = 0

    func image(forKey key: String) -> UIImage? {
        storage[key]
    }

    func insert(_ image: UIImage, forKey key: String) {
        storage[key] = image
    }

    func remove(forKey key: String) {
        storage.removeValue(forKey: key)
    }

    func clear() {
        storage.removeAll()
        clearCallCount += 1
    }
}

@MainActor
final class ImageLoaderTests: XCTestCase {
    private var session: URLSession!
    private var cache: TestImageCache!

    override func setUp() {
        super.setUp()
        cache = TestImageCache()
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [ImageTestURLProtocol.self]
        session = URLSession(configuration: config)
        ImageTestURLProtocol.handler = nil
    }

    override func tearDown() {
        ImageTestURLProtocol.handler = nil
        session = nil
        cache = nil
        super.tearDown()
    }

    private func createTestImageData() -> Data {
        let size = CGSize(width: 10, height: 10)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            UIColor.blue.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
        return image.pngData() ?? Data()
    }

    func testNilURLFailsImmediately() async {
        let loader = ImageLoader(url: nil, cache: cache, session: session)
        await loader.load()
        if case .failure = loader.state {
            // Success
        } else {
            XCTFail("Expected failure for nil URL")
        }
    }

    func testCachedImageReturnsSynchronouslyWithoutNetwork() async {
        let url = URL(string: "https://example.com/logo.png")!
        let image = UIImage()
        cache.insert(image, forKey: url.absoluteString)

        let loader = ImageLoader(url: url, cache: cache, session: session)
        await loader.load()

        if case .success(let loaded) = loader.state {
            XCTAssertEqual(loaded, image)
        } else {
            XCTFail("Expected success from cache")
        }
    }

    func testSuccessfulNetworkLoadInsertsIntoCache() async {
        let url = URL(string: "https://example.com/logo.png")!
        let data = createTestImageData()
        ImageTestURLProtocol.handler = { request in
            guard let requestURL = request.url,
                  let response = HTTPURLResponse(url: requestURL, statusCode: 200, httpVersion: nil, headerFields: nil) else {
                throw URLError(.badServerResponse)
            }
            return (response, data)
        }

        let loader = ImageLoader(url: url, cache: cache, session: session)
        await loader.load()

        if case .success = loader.state {
            XCTAssertNotNil(cache.image(forKey: url.absoluteString))
        } else {
            XCTFail("Expected success after network load")
        }
    }

    func testNon2xxStatusCodeFails() async {
        let url = URL(string: "https://example.com/logo.png")!
        ImageTestURLProtocol.handler = { request in
            guard let requestURL = request.url,
                  let response = HTTPURLResponse(url: requestURL, statusCode: 404, httpVersion: nil, headerFields: nil) else {
                throw URLError(.badServerResponse)
            }
            return (response, Data())
        }

        let loader = ImageLoader(url: url, cache: cache, session: session)
        await loader.load()

        if case .failure = loader.state {
            XCTAssertNil(cache.image(forKey: url.absoluteString))
        } else {
            XCTFail("Expected failure for non-2xx status code")
        }
    }

    func testInvalidImageDataFails() async {
        let url = URL(string: "https://example.com/logo.png")!
        ImageTestURLProtocol.handler = { request in
            guard let requestURL = request.url,
                  let response = HTTPURLResponse(url: requestURL, statusCode: 200, httpVersion: nil, headerFields: nil) else {
                throw URLError(.badServerResponse)
            }
            return (response, Data("not an image".utf8))
        }

        let loader = ImageLoader(url: url, cache: cache, session: session)
        await loader.load()

        if case .failure = loader.state {
            XCTAssertNil(cache.image(forKey: url.absoluteString))
        } else {
            XCTFail("Expected failure for corrupt image data")
        }
    }

    func testChannelListViewModelClearsInjectedCache() async {
        let fetchUseCase = DefaultFetchChannelsUseCase(repository: DeveloperStubRepository(scenario: "success"))
        let reachability = ReachabilityServiceImpl()
        let haptics = HapticServiceImpl()
        let viewModel = ChannelListViewModel(
            fetchChannels: fetchUseCase,
            reachability: reachability,
            haptics: haptics,
            imageCache: cache
        )

        XCTAssertEqual(cache.clearCallCount, 0)
        await viewModel.clearCache()
        XCTAssertEqual(cache.clearCallCount, 1)
    }
}
