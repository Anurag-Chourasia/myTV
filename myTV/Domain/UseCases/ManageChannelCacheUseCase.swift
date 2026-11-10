//
//  ManageChannelCacheUseCase.swift
//  myTV
//

import Foundation

protocol ManageChannelCacheUseCase: Sendable {
    func clearCache() async throws
    func getCachedEntryCount() -> Int
    func getFormattedCacheSize() -> String
}

final class DefaultManageChannelCacheUseCase: ManageChannelCacheUseCase {

    private let repository: any ChannelRepository

    init(repository: any ChannelRepository) {
        self.repository = repository
    }

    func clearCache() async throws {
        repository.clearCache()
    }

    func getCachedEntryCount() -> Int {
        repository.cachedEntryCount
    }

    func getFormattedCacheSize() -> String {
        repository.formattedCacheSize
    }
}
