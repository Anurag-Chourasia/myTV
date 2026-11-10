//
//  CachedAsyncImage.swift
//  myTV
//
//  Created by Anurag Chourasia on 26/01/26.
//


import SwiftUI
import CommonNetworkingKit

struct CachedAsyncImage<Placeholder: View>: View {

    @StateObject private var loader: ImageLoader
    private let placeholder: Placeholder

    init(
        url: URL?,
        cache: ImageCache? = nil,
        fetcher: (any ImageDataFetching)? = nil,
        @ViewBuilder placeholder: () -> Placeholder
    ) {
        _loader = StateObject(
            wrappedValue: ImageLoader(url: url, cache: cache, fetcher: fetcher)
        )
        self.placeholder = placeholder()
    }

    var body: some View {
        content
            .task {
                await loader.load()
            }
    }

    @ViewBuilder
    private var content: some View {
        switch loader.state {

        case .idle, .loading:
            ZStack {
                placeholder
                ProgressView()
            }

        case .success(let image):
            Image(uiImage: image)
                .resizable()

        case .failure:
            placeholder
        }
    }
}
