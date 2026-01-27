//
//  ChannelDTO.swift
//  myTV
//
//  Created by Anurag Chourasia on 23/01/26.
//


struct ChannelDTO: Codable {
    let id: String
    let name: String
    let alt_names: [String]
    let network: String?
    let owners: [String]
    let country: String
    let categories: [String]
    let is_nsfw: Bool
    let launched: String?
    let closed: String?
    let replaced_by: String?
    let website: String?
}
