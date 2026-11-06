//
//  FetchChannelsUseCase.swift
//  myTV
//

import Foundation

protocol FetchChannelsUseCase {
    func execute() async throws -> [Channel]
    func clearCache()
}
