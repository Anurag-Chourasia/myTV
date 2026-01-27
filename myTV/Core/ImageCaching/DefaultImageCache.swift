//
//  DefaultImageCache.swift
//  myTV
//
//  Created by Anurag Chourasia on 26/01/26.
//


import UIKit

final class DefaultImageCache: ImageCache {

    static let shared = DefaultImageCache()

    private let cache = NSCache<NSString, UIImage>()

    private init() {
        cache.countLimit = 300
    }

    func image(forKey key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }

    func insert(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
    }

    func clear() {
        cache.removeAllObjects()
    }
}
