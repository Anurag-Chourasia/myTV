//
//  LoadingView.swift
//  myTV
//
//  Created by Anurag Chourasia on 23/01/26.
//

import SwiftUI
import DesignTokensKit

struct LoadingView: View {
    let viewModel: LoadingViewModel

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()

            VStack(spacing: Spacing.twelve) {
                ProgressView()
                Text(viewModel.message)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .padding(Spacing.twenty)
            .background(.ultraThinMaterial)
            .cornerRadius(CornerRadius.twelve)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(Text(viewModel.message))
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(edges: .all)
    }
}
