//
//  CategoryDisplay.swift
//  myTV
//
//  Created by Anurag Chourasia on 08/02/26.
//

import Foundation

enum CategoryDisplay {

    static func label(for value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return value }

        let key = normalizedKey(from: trimmed)
        if let mapped = mapping[key] {
            return mapped
        }

        return titleCased(from: trimmed)
    }

    static func sortKey(for value: String) -> String {
        normalizedSortKey(from: label(for: value))
    }

    private static func normalizedKey(from value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "&", with: "and")
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
    }

    private static func titleCased(from value: String) -> String {
        value
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .capitalized
    }

    private static func normalizedSortKey(from value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        var result = trimmed

        while let first = result.unicodeScalars.first {
            if CharacterSet.alphanumerics.contains(first) {
                break
            }
            result.removeFirst()
        }

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static let mapping: [String: String] = [
        "animation": "🎞 Animation",
        "auto": "🚗 Auto",
        "business": "💼 Business",
        "classic": "🎼 Classic",
        "comedy": "😂 Comedy",
        "cooking": "🍳 Cooking",
        "culture": "🎨 Culture",
        "documentary": "🎥 Documentary",
        "education": "📚 Education",
        "entertainment": "🎭 Entertainment",
        "family": "👨‍👩‍👧‍👦 Family",
        "general": "⭐️ General",
        "interactive": "🕹 Interactive",
        "kids": "🧒 Kids",
        "legislative": "🏛 Legislative",
        "lifestyle": "✨ Lifestyle",
        "movies": "🎬 Movies",
        "music": "🎵 Music",
        "news": "📰 News",
        "outdoor": "🏕 Outdoor",
        "public": "🏛 Public",
        "relax": "🧘 Relax",
        "religious": "🙏 Religious",
        "science": "🔬 Science",
        "series": "📺 Series",
        "shop": "🛍 Shop",
        "sports": "🏆 Sports",
        "travel": "✈️ Travel",
        "weather": "⛅️ Weather",
        "xxx": "🔞 Adult"
    ]
}
