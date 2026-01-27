//
//  File.swift
//  myTV
//
//  Created by Anurag Chourasia on 23/01/26.
//


extension Stream {
    init(dto: StreamDTO) {
        self.id = dto.url              
        self.title = dto.title
        self.url = dto.url
        self.quality = dto.quality
    }
}
