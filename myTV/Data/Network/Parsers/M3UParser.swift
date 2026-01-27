//
//  M3UChannel.swift
//  myTV
//
//  Created by Anurag Chourasia on 23/01/26.
//

import SwiftUI

struct M3UChannel {
    let name: String
    let url: String
    let attributes: [String: String]
}

final class M3UParser {

    func parse(_ data: Data) -> [M3UChannel] {
        guard let text = String(data: data, encoding: .utf8) else { return [] }

        var result: [M3UChannel] = []
        var currentAttributes: [String: String] = [:]
        var currentName = ""

        for line in text.components(separatedBy: .newlines) {
            if line.hasPrefix("#EXTINF") {
                currentAttributes = parseAttributes(line)
                currentName = line.components(separatedBy: ",").last ?? ""
            } else if line.hasPrefix("http") {
                result.append(
                    M3UChannel(
                        name: currentName,
                        url: line,
                        attributes: currentAttributes
                    )
                )
            }
        }
        return result
    }

    private func parseAttributes(_ line: String) -> [String: String] {
        var dict: [String: String] = [:]
        let parts = line.components(separatedBy: " ")
        for part in parts where part.contains("=") {
            let kv = part.split(separator: "=", maxSplits: 1)
            if kv.count == 2 {
                dict[String(kv[0])] = kv[1].replacingOccurrences(of: "\"", with: "")
            }
        }
        return dict
    }
}
