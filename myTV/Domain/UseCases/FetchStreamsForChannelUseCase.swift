//
//  FetchStreamsForChannelUseCase.swift
//  myTV
//

import Foundation

protocol FetchStreamsForChannelUseCase {
    func execute(channelId: String) async throws -> [Stream]
}
