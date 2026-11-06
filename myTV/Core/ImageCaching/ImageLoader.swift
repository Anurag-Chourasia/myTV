//
//  ImageLoader.swift
//  myTV
//
//  Created by Anurag Chourasia on 26/01/26.
//


import SwiftUI
import Combine

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
    private let session: URLSession

    init(url: URL?, cache: ImageCache? = nil, session: URLSession = .shared) {
        self.url = url
        self.cache = cache ?? DefaultImageCache.shared
        self.session = session
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
            let (data, response) = try await session.data(from: url)

            if Task.isCancelled { return }

            guard
                let http = response as? HTTPURLResponse,
                (200..<300).contains(http.statusCode),
                let image = UIImage(data: data)
            else {
                state = .failure
                return
            }

            cache.insert(image, forKey: key)
            state = .success(image)

        } catch {
            if Task.isCancelled { return }
            state = .failure
            #if DEBUG
            print("❌ Image load failed:", error.localizedDescription)
            #endif
        }
    }
}
