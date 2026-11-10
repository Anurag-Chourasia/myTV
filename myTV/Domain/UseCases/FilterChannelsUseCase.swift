//
//  FilterChannelsUseCase.swift
//  myTV
//

import Foundation

protocol FilterChannelsUseCase: Sendable {
    func execute(
        channels: [Channel],
        query: String,
        categories: Set<String>,
        countries: Set<String>,
        scope: ChannelScope,
        favorites: Set<String>,
        hideUnavailableStreams: Bool,
        grouping: ChannelGrouping,
        sectionSort: ChannelSortOrder,
        channelSort: ChannelSortOrder
    ) -> [(String, [Channel])]
}

final class DefaultFilterChannelsUseCase: FilterChannelsUseCase {

    init() {}

    func execute(
        channels: [Channel],
        query: String,
        categories: Set<String>,
        countries: Set<String>,
        scope: ChannelScope,
        favorites: Set<String>,
        hideUnavailableStreams: Bool,
        grouping: ChannelGrouping,
        sectionSort: ChannelSortOrder,
        channelSort: ChannelSortOrder
    ) -> [(String, [Channel])] {
        let filtered = channels.filter {
            (!hideUnavailableStreams || $0.hasStreams != false) &&
            (scope == .all || favorites.contains($0.id)) &&
            (query.isEmpty || $0.name.localizedCaseInsensitiveContains(query)) &&
            (countries.isEmpty || countries.contains($0.country)) &&
            (categories.isEmpty || !Set($0.categories).isDisjoint(with: categories))
        }

        func sortChannels(_ c: [Channel]) -> [Channel] {
            let comparer: (Channel, Channel) -> Bool = { lhs, rhs in
                lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
            return channelSort == .ascending
                ? c.sorted(by: comparer)
                : c.sorted { comparer($1, $0) }
        }

        var dict: [String: [Channel]] = [:]

        switch grouping {
        case .name:
            dict = Dictionary(grouping: filtered) { String($0.name.prefix(1)).uppercased() }
        case .country:
            dict = Dictionary(grouping: filtered) { $0.country }
        case .category:
            for channel in filtered {
                for category in channel.categories {
                    dict[category, default: []].append(channel)
                }
            }
        }

        let displayKey: (String) -> String = { key in
            switch grouping {
            case .country:
                return CountryDisplay.sortKey(for: key)
            case .category:
                return CategoryDisplay.sortKey(for: key)
            case .name:
                return key
            }
        }

        let keys = sectionSort == .ascending
            ? dict.keys.sorted { displayKey($0) < displayKey($1) }
            : dict.keys.sorted { displayKey($0) > displayKey($1) }

        return keys.map { ($0, sortChannels(dict[$0] ?? [])) }
    }
}
