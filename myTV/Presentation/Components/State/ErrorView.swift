import DesignTokensKit
//
//  ErrorView.swift
//  myTV
//
//  Created by Anurag Chourasia on 23/01/26.
//

import SwiftUI
import UIComponentsKit

struct ErrorView: View {
    let viewModel: ErrorViewModel
    let message: String
    let retry: () -> Void

    var body: some View {
        StateMessage {
            Image(\.wifiExclamationmark)
        } title: {
            Text(viewModel.title)
        } detail: {
            Text(message)
        } actions: {
            Button(viewModel.retryTitle, action: retry)
        }
        .padding(.all, \.sixteen)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }
}
