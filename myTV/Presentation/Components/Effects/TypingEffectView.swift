//
//  TypingEffectView.swift
//  myTV
//
//  Created by Anurag Chourasia on 23/01/26.
//


import SwiftUI

struct TypingEffectView: View {
    @StateObject private var viewModel = TypingEffectViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(viewModel.displayedText)
                .font(.system(size: 16))
                .lineLimit(viewModel.isExpanded ? nil : 2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .animation(.none, value: viewModel.displayedText)

            Button {
                withAnimation(.easeInOut) {
                    if viewModel.isExpanded {
                        viewModel.collapse()
                    } else {
                        viewModel.expand()
                    }
                }
            } label: {
                Text(viewModel.isExpanded ? L10n.App.showLess : L10n.App.readMore)
                    .font(.system(size: 16, weight: .bold))
            }
        }
        .padding()
    }
}
