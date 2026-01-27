//
//  Endpoints.swift
//  myTV
//
//  Created by Anurag Chourasia on 23/01/26.
//

enum IPTVEndpoint {
    static let base = "https://iptv-org.github.io"

    // Streaming playlists
    static let allStreams = "\(base)/iptv/index.m3u"
    static let categoryIndex = "\(base)/iptv/index.category.m3u"
    static func category(_ id: String) -> String {
        "\(base)/iptv/categories/\(id).m3u"
    }

    // APIs
    static let channels = "\(base)/api/channels.json"
    static let feeds = "\(base)/api/feeds.json"
    static let streams = "\(base)/api/streams.json"
    static let logos = "\(base)/api/logos.json"
    static let categories = "\(base)/api/categories.json"
    static let languages = "\(base)/api/languages.json"
    static let countries = "\(base)/api/countries.json"
    static let regions = "\(base)/api/regions.json"
}
