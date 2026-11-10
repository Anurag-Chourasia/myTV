//
//  CategoryDisplay.swift
//  myTV
//
//  Created by Anurag Chourasia on 08/02/26.
//

import Foundation
import FoundationKit
import LocalizationKit

enum CategoryDisplay {

    static func label(for value: String) -> String {
        let trimmed = StringFormatting.trimmed(value)
        guard !trimmed.isEmpty else { return value }

        let key = normalizedKey(from: trimmed)
        if let keyPath = keyPathMapping[key] {
            return String(keyPath)
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
        let trimmed = StringFormatting.trimmed(value)
        var result = trimmed

        while let first = result.unicodeScalars.first {
            if CharacterSet.alphanumerics.contains(first) {
                break
            }
            result.removeFirst()
        }

        return StringFormatting.trimmed(result)
    }

    private static let keyPathMapping: [String: KeyPath<MyTVStrings, String>] = [
        "animation": \.categoryAnimation,
        "auto": \.categoryAuto,
        "business": \.categoryBusiness,
        "classic": \.categoryClassic,
        "comedy": \.categoryComedy,
        "cooking": \.categoryCooking,
        "culture": \.categoryCulture,
        "documentary": \.categoryDocumentary,
        "education": \.categoryEducation,
        "entertainment": \.categoryEntertainment,
        "family": \.categoryFamily,
        "general": \.categoryGeneral,
        "interactive": \.categoryInteractive,
        "kids": \.categoryKids,
        "legislative": \.categoryLegislative,
        "lifestyle": \.categoryLifestyle,
        "movies": \.categoryMovies,
        "music": \.categoryMusic,
        "news": \.categoryNews,
        "outdoor": \.categoryOutdoor,
        "public": \.categoryPublic,
        "relax": \.categoryRelax,
        "religious": \.categoryReligious,
        "science": \.categoryScience,
        "series": \.categorySeries,
        "shop": \.categoryShop,
        "sports": \.categorySports,
        "travel": \.categoryTravel,
        "weather": \.categoryWeather,
        "xxx": \.categoryAdult
    ]
}
