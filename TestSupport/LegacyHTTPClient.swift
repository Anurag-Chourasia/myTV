//
//  HTTPClient.swift
//  myTV
//
//  Created by Anurag Chourasia on 23/01/26.
//


import Foundation

final class URLSessionHTTPClient: HTTPClient {

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func get<T: Decodable>(_ url: URL) async throws -> T {
        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode(T.self, from: data)
    }

    func getRaw(_ url: URL) async throws -> Data {
        let (data, _) = try await session.data(from: url)
        return data
    }
}
