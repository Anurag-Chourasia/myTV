//
//  ChannelRepository.swift
//  myTV
//
//  Created by Anurag Chourasia on 23/01/26.
//

import Foundation

protocol ChannelRepository: Sendable {
    func fetchChannels() async throws -> [Channel]
    func fetchStreams(channelId: String) async throws -> [Stream]
    func clearCache()
    var cachedEntryCount: Int { get }
    var formattedCacheSize: String { get }
}

extension ChannelRepository {
    var cachedEntryCount: Int { 0 }
    var formattedCacheSize: String { "0 KB" }
}
