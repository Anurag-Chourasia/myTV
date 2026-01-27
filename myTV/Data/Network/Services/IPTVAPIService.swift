//
//  IPTVAPIService.swift
//  myTV
//
//  Created by Anurag Chourasia on 23/01/26.
//

import SwiftUI

protocol IPTVAPIService {
    func fetchChannels() async throws -> [ChannelDTO]
    func fetchStreams() async throws -> [StreamDTO]
    func fetchLogos() async throws -> [LogoDTO]
    func fetchCategoryPlaylist(_ id: String) async throws -> [M3UChannel]
}

final class IPTVAPIServiceImpl: IPTVAPIService {

    private let client: HTTPClient
    private let parser = M3UParser()

    init(client: HTTPClient) {
        self.client = client
    }

    func fetchChannels() async throws -> [ChannelDTO] {
        try await client.get(URL(string: IPTVEndpoint.channels)!)
    }

    func fetchStreams() async throws -> [StreamDTO] {
        try await client.get(URL(string: IPTVEndpoint.streams)!)
    }

    func fetchLogos() async throws -> [LogoDTO] {
        try await client.get(URL(string: IPTVEndpoint.logos)!)
    }

    func fetchCategoryPlaylist(_ id: String) async throws -> [M3UChannel] {
        let data = try await client.getRaw(URL(string: IPTVEndpoint.category(id))!)
        return parser.parse(data)
    }
}
