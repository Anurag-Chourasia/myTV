//
//  CountryDisplay.swift
//  myTV
//
//  Created by Anurag Chourasia on 08/02/26.
//

import Foundation

enum CountryDisplay {

    nonisolated static func label(for value: String, locale: Locale = .current) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return value }

        let code = normalizedRegionCode(from: trimmed)
        let name = localizedCountryName(for: code ?? trimmed, locale: locale)
        let flag = code.flatMap(flagEmoji)

        if let flag, let name {
            return "\(flag) \(name)"
        }

        if let name {
            return name
        }

        return flag ?? trimmed
    }

    nonisolated static func sortKey(for value: String, locale: Locale = .current) -> String {
        normalizedSortKey(from: label(for: value, locale: locale))
    }

    private nonisolated static func normalizedRegionCode(from value: String) -> String? {
        let upper = value.uppercased()
        if upper.count == 2, upper.unicodeScalars.allSatisfy({ $0.isASCII }) {
            return upper
        }
        return nil
    }

    private nonisolated static func localizedCountryName(
        for value: String,
        locale: Locale
    ) -> String? {
        if let name = locale.localizedString(forRegionCode: value.uppercased()) {
            return name
        }

        return nil
    }

    private nonisolated static func flagEmoji(from regionCode: String) -> String? {
        guard regionCode.count == 2 else { return nil }
        let base: UInt32 = 127397
        var scalars: [UnicodeScalar] = []
        for scalar in regionCode.uppercased().unicodeScalars {
            guard let regional = UnicodeScalar(base + scalar.value) else {
                return nil
            }
            scalars.append(regional)
        }
        return String(String.UnicodeScalarView(scalars))
    }

    private nonisolated static func normalizedSortKey(from value: String) -> String {
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
}
