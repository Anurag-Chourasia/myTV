//
//  ChannelFilterOptions.swift
//  myTV
//

import Foundation

enum ChannelGrouping: String, CaseIterable, Identifiable, Sendable {
    case name
    case country
    case category

    var id: String { rawValue }
}

enum ChannelSortOrder: String, CaseIterable, Identifiable, Sendable {
    case ascending
    case descending

    var id: String { rawValue }
}

enum ChannelScope: String, CaseIterable, Identifiable, Sendable {
    case all
    case favorites

    var id: String { rawValue }
}
