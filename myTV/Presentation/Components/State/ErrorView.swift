//
//  ErrorView.swift
//  myTV
//
//  Created by Anurag Chourasia on 23/01/26.
//

import SwiftUI

struct ErrorView: View {

    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.exclamationmark")
                .font(.largeTitle)

            Text(L10n.Error.Generic.title)
                .font(.headline)

            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button(L10n.App.retry, action: retry)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
