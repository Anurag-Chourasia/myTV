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
            DesignColor.black.opacity(OpacityToken.p0_35)
                .ignoresSafeArea()

            VStack(spacing: Spacing.twelve) {
                ProgressView()
                Text(viewModel.message)
                    .font(Typography.footnote)
                    .foregroundColor(DesignColor.secondary)
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
