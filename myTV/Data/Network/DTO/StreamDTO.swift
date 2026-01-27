//
//  StreamDTO.swift
//  myTV
//
//  Created by Anurag Chourasia on 23/01/26.
//

struct StreamDTO: Decodable {
    let channel: String?
    let feed: String?
    let title: String
    let url: String
    let referrer: String?
    let user_agent: String?
    let quality: String?
}
