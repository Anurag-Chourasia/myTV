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

    var body: some View {
        StateMessage {
            Image(systemName: systemImage)
        } title: {
            Text(title)
        } detail: {
            Text(message)
        }
        .padding(.all, Spacing.system)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }
}
