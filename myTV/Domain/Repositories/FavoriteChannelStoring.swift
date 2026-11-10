//
//  FavoriteChannelStoring.swift
//  myTV
//
//  Created by Anurag Chourasia on 23/01/26.
//

import Foundation

protocol FavoriteChannelStoring: Sendable {
    func load() -> Set<String>
    func save(_ ids: Set<String>)
}

final class InMemoryFavoriteChannelStore: FavoriteChannelStoring, @unchecked Sendable {
    private var ids: Set<String>
    private let lock = NSLock()

    init(ids: Set<String> = []) {
        self.ids = ids
    }

    func load() -> Set<String> {
        lock.lock()
        defer { lock.unlock() }
        return ids
    }

    func save(_ ids: Set<String>) {
        lock.lock()
        defer { lock.unlock() }
        self.ids = ids
    }
}
