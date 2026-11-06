//
//  DefaultFetchStreamsForChannelUseCase.swift
//  myTV
//
//  Created by Anurag Chourasia on 23/01/26.
//

final class DefaultFetchStreamsForChannelUseCase: FetchStreamsForChannelUseCase {

    private let repository: ChannelRepository

    init(repository: ChannelRepository) {
        self.repository = repository
    }

    func execute(channelId: String) async throws -> [Stream] {
        try await repository.fetchStreams(channelId: channelId)
    }
}
