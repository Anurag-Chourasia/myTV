//
//  Channel.swift
//  myTV
//
//  Created by Anurag Chourasia on 23/01/26.
//

import SwiftUI

struct Channel: Identifiable, Equatable {
    let id: String
    let name: String
    let country: String
    let categories: [String]
    let isNSFW: Bool
    let logoURL: URL?
    /// Nil means the directory availability could not be checked.
    var hasStreams: Bool? = nil

    static func == (lhs: Channel, rhs: Channel) -> Bool {
        lhs.id == rhs.id
    }
}
