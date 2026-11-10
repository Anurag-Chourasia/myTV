//
//  FetchStreamsForChannelUseCase.swift
//  myTV
//

import Foundation

protocol FetchStreamsForChannelUseCase: Sendable {
    func execute(channelId: String) async throws -> [Stream]
}

final class DefaultFetchStreamsForChannelUseCase: FetchStreamsForChannelUseCase {

    private let repository: any ChannelRepository

    init(repository: any ChannelRepository) {
        self.repository = repository
    }

    func execute(channelId: String) async throws -> [Stream] {
        try await repository.fetchStreams(channelId: channelId)
    }
}
