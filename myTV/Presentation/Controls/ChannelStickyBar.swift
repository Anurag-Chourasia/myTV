//
//  ChannelStickyBar.swift
//  myTV
//
//  Created by Anurag Chourasia on 25/01/26.
//

import SwiftUI
import DesignTokensKit

struct ChannelStickyBar: View {

    @Binding var scope: ChannelListViewModel.ChannelScope

    var body: some View {
        HStack(spacing: \.eight) {
            ForEach(ChannelListViewModel.ChannelScope.allCases) { tab in
                Button {
                    scope = tab
                } label: {
                    Text(tab.title)
                        .font(Typography.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, \.eight)
                        .background(
                            scope == tab
                            ? ColorTheme.default.accentColor.opacity(OpacityTheme.default.p0_15)
                            : ColorTheme.default.clear
                        )
                        .cornerRadius(\.ten)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(tab.title))
                .accessibilityValue(
                    scope == tab ? Text(VoiceOver.A11y.selected) : Text("")
                )
            }
        }
        .padding(\.eight)
        .background(\.groupedSecondary)
        .clipShape(RoundedRectangle(cornerRadius: \.fourteen))
        .padding(.horizontal, \.sixteen)
        .padding(.top, \.four)
    }
}
