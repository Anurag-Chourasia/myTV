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
