//
//  ChannelRepositoryImpl.swift
//  myTV
//
//  Created by Anurag Chourasia on 23/01/26.
//


import Foundation

final class ChannelRepositoryImpl: ChannelRepository {

    private let api: IPTVAPIService
    private let cache: ChannelCache

    init(api: IPTVAPIService, cache: ChannelCache) {
        self.api = api
        self.cache = cache
    }

    // MARK: - Channels (cached)
    func fetchChannels() async throws -> [Channel] {

        async let channelsDTO = api.fetchChannels()
        async let logosDTO = api.fetchLogos()
        async let streamChannelIDs = availableStreamChannelIDs()

        let (channels, logos, availableIDs) = try await (channelsDTO, logosDTO, streamChannelIDs)

        let logoMap = buildLogoMap(logos)

        return channels.map { dto in
            let key = normalize(dto.id)

            return Channel(
                id: dto.id,
                name: dto.name,
                country: dto.country,
                categories: dto.categories,
                isNSFW: dto.is_nsfw,
                logoURL: logoMap[key],
                hasStreams: availableIDs.map { $0.contains(dto.id) }
            )
        }
    }

    /// One directory request for the whole catalog, not a request per tile.
    /// A failed lookup must never label every channel as unavailable.
    private func availableStreamChannelIDs() async throws -> Set<String>? {
        do {
            let streams = try await api.fetchStreams()
            try Task.checkCancellation()
            return Set(streams.compactMap(\.channel))
        } catch {
            if Task.isCancelled || error is CancellationError || (error as? URLError)?.code == .cancelled {
                throw CancellationError()
            }
            return nil
        }
    }

    // MARK: - Streams (network-only)
    func fetchStreams(channelId: String) async throws -> [Stream] {
        let dtos = try await api.fetchStreams()
        return dtos
            .filter { $0.channel == channelId }
            .map { Stream(dto: $0) }
    }

    func clearCache() {
        cache.clear()
    }
}

private extension ChannelRepositoryImpl {
    private func buildLogoMap(_ logos: [LogoDTO]) -> [String: URL] {
        let grouped = Dictionary(grouping: logos) {
            normalize($0.channel)
        }
        var result: [String: URL] = [:]
        for (key, candidates) in grouped {
            let sorted = candidates.sorted { lhs, rhs in
                let lhsRank = logoRank(lhs)
                let rhsRank = logoRank(rhs)
                if lhsRank != rhsRank {
                    return lhsRank > rhsRank
                }
                return (lhs.width * lhs.height) > (rhs.width * rhs.height)
            }
            if let best = sorted.first,
               let urlString = best.url,
               let url = URL(string: urlString) {
                result[key] = url
            }
        }
        return result
    }

    private func logoRank(_ logo: LogoDTO) -> Int {
        switch logo.format {
        case .png: return 3
        case .jpeg: return 2
        case .svg: return 1
        default: return 0
        }
    }

    func normalize(_ value: String) -> String {
        value
            .lowercased()
            .replacingOccurrences(
                of: Localizable.App.Normalize.regex,
                with: "",
                options: .regularExpression
            )
    }
}
