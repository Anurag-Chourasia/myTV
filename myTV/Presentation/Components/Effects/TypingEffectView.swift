//
//  TypingEffectView.swift
//  myTV
//
//  Created by Anurag Chourasia on 23/01/26.
//


import SwiftUI

struct TypingEffectView: View {
    @StateObject private var viewModel = TypingEffectViewModel()
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(viewModel.displayedText)
                .font(.body)
                .lineLimit(viewModel.isExpanded ? nil : (dynamicTypeSize.isAccessibilitySize ? 3 : 2))
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
                Text(viewModel.toggleButtonTitle)
                    .font(.body.weight(.semibold))
            }
        }
        .padding()
    }
}
