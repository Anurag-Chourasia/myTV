//
//  Channel+Mapper.swift
//  myTV
//
//  Created by Anurag Chourasia on 23/01/26.
//

import Foundation

extension Channel {
    init(dto: ChannelDTO, logoURL: URL? = nil) {
        self.id = dto.id
        self.name = dto.name
        self.country = dto.country
        self.categories = dto.categories
        self.isNSFW = dto.is_nsfw
        self.logoURL = logoURL
    }
}
