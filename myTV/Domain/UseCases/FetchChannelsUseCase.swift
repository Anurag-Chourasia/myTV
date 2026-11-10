//
//  FetchChannelsUseCase.swift
//  myTV
//

import Foundation

protocol FetchChannelsUseCase: Sendable {
    func execute() async throws -> [Channel]
}

final class DefaultFetchChannelsUseCase: FetchChannelsUseCase {

    private let repository: any ChannelRepository

    init(repository: any ChannelRepository) {
        self.repository = repository
    }

    func execute() async throws -> [Channel] {
        try await repository.fetchChannels()
    }
}
