//
//  ImageLoader.swift
//  myTV
//
//  Created by Anurag Chourasia on 26/01/26.
//


import SwiftUI
import Combine
import CommonNetworkingKit

@MainActor
final class ImageLoader: ObservableObject {

    enum State {
        case idle
        case loading
        case success(UIImage)
        case failure
    }

    @Published private(set) var state: State = .idle

    private let url: URL?
    private let cache: ImageCache
    private let fetcher: any ImageDataFetching

    init(
        url: URL?,
        cache: ImageCache? = nil,
        fetcher: (any ImageDataFetching)? = nil
    ) {
        self.url = url
        self.cache = cache ?? DefaultImageCache.shared
        self.fetcher = fetcher ?? AppDI.shared.getImageDataFetcher()
    }

    init(
        url: URL?,
        cache: ImageCache? = nil,
        session: URLSession
    ) {
        self.url = url
        self.cache = cache ?? DefaultImageCache.shared
        self.fetcher = ImageDataFetcher(session: session)
    }

    func load() async {
        guard let url else {
            state = .failure
            return
        }

        let key = url.absoluteString

        if let cached = cache.image(forKey: key) {
            state = .success(cached)
            return
        }

        state = .loading

        do {
            let data = try await fetcher.fetchData(for: url)

            if Task.isCancelled { return }

            guard let image = UIImage(data: data) else {
                state = .failure
                return
            }

            cache.insert(image, forKey: key)
            state = .success(image)

        } catch {
            if Task.isCancelled { return }
            state = .failure
        }
    }
}
