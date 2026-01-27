//
//  ChannelRepository.swift
//  myTV
//
//  Created by Anurag Chourasia on 23/01/26.
//

protocol ChannelRepository {
    func fetchChannels() async throws -> [Channel]
    func fetchStreams(channelId: String) async throws -> [Stream]
    func clearCache()
}
