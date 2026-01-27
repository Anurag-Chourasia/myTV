//
//  FetchChannelsInteractor.swift
//  myTV
//
//  Created by Anurag Chourasia on 23/01/26.
//

protocol FetchChannelsUseCase {
    func execute() async throws -> [Channel]
}

final class FetchChannelsInteractor: FetchChannelsUseCase {

    private let repository: ChannelRepository

    public init(repository: ChannelRepository) {
        self.repository = repository
    }

    public func execute() async throws -> [Channel] {
        try await repository.fetchChannels()
    }
    
    public func clearCache() {
       repository.clearCache()
    }
}
