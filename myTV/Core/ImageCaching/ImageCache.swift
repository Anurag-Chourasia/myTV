//
//  ImageCache.swift
//  myTV
//
//  Created by Anurag Chourasia on 26/01/26.
//

import UIKit

protocol ImageCache {
    func image(forKey key: String) -> UIImage?
    func insert(_ image: UIImage, forKey key: String)
    func clear()
}
