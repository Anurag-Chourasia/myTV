//
//  HTTPClient.swift
//  myTV
//
//  Created by Anurag Chourasia on 23/01/26.
//


import Foundation
import CommonNetworking

protocol HTTPClient {
    func get<T: Decodable>(_ url: URL) async throws -> T
    func getRaw(_ url: URL) async throws -> Data
}

/// Preserves MyTV response and cancellation semantics over shared transport.
final class CommonNetworkingHTTPClient: HTTPClient {

    private let transport: CommonNetworking.HTTPClient

    init(session: URLSession = .shared) {
        #if DEBUG
        let logging = UserDefaults.standard.object(forKey: "developer.httpLogs") as? Bool
            ?? (ProcessInfo.processInfo.environment["HTTP_LOGGING"] == "1")
        self.transport = CommonNetworking.HTTPClient(session: session, logger: logging ? .console : nil)
        #else
        self.transport = CommonNetworking.HTTPClient(session: session)
        #endif
    }

    func get<T: Decodable>(_ url: URL) async throws -> T {
        let data = try await getRaw(url)
        return try JSONDecoder().decode(T.self, from: data)
    }

    func getRaw(_ url: URL) async throws -> Data {
        do {
            // MyTV historically consumes bodies regardless of HTTP status.
            return try await transport.send(URLRequest(url: url)).data
        } catch is CancellationError {
            // View models display localizedDescription; retain their existing URL error.
            throw URLError(.cancelled)
        }
    }
}
