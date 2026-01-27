//
//  EmptyStateView.swift
//  myTV
//
//  Created by Anurag Chourasia on 23/01/26.
//

import SwiftUI

struct EmptyStateView: View {

    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.largeTitle)

            Text(title)
                .font(.headline)

            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
