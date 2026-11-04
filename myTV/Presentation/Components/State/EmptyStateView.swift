import DesignTokensKit
//
//  EmptyStateView.swift
//  myTV
//
//  Created by Anurag Chourasia on 23/01/26.
//

import SwiftUI
import UIComponentsKit

struct EmptyStateView: View {

    let title: String
    let message: String
    let systemImage: String

    init(title: String, message: String, systemImage: String) {
        self.title = title
        self.message = message
        self.systemImage = systemImage
    }

    init(title: String, message: String, symbol: KeyPath<SymbolTheme, AppSymbol>, theme: SymbolTheme = .default) {
        self.title = title
        self.message = message
        self.systemImage = theme[keyPath: symbol].systemName
    }

    var body: some View {
        StateMessage {
            Image(systemName: systemImage)
        } title: {
            Text(title)
        } detail: {
            Text(message)
        }
        .padding(.all, \.sixteen)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }
}
