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
            ColorTheme.default.black.opacity(OpacityTheme.default.p0_35)
                .ignoresSafeArea()

            VStack(spacing: \.twelve) {
                ProgressView()
                Text(viewModel.message)
                    .font(Typography.footnote)
                    .foregroundColor(\.secondary)
            }
            .padding(\.twenty)
            .background(.ultraThinMaterial)
            .cornerRadius(\.twelve)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(Text(viewModel.message))
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(edges: .all)
    }
}
