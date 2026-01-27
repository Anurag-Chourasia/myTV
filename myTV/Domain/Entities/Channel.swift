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

    static func == (lhs: Channel, rhs: Channel) -> Bool {
        lhs.id == rhs.id
    }
}
