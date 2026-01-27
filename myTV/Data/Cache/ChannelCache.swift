//
//  ChannelCache.swift
//  myTV
//
//  Created by Anurag Chourasia on 23/01/26.
//

protocol ChannelCache {
    func save(_ channels: [ChannelDTO])
    func load() -> [ChannelDTO]?
    func clear()
}
