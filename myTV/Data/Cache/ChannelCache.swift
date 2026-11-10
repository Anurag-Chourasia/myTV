//
//  ChannelCache.swift
//  myTV
//
//  Created by Anurag Chourasia on 23/01/26.
//

import Foundation

protocol ChannelCache {
    func save(_ channels: [ChannelDTO])
    func load() -> [ChannelDTO]?
    func clear()
    var entryCount: Int { get }
    var formattedFileSize: String { get }
}

extension ChannelCache {
    var entryCount: Int { 0 }
    var formattedFileSize: String { "0 KB" }
}
