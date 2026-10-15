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
        HStack(spacing: Spacing.eight) {
            ForEach(ChannelListViewModel.ChannelScope.allCases) { tab in
                Button {
                    scope = tab
                } label: {
                    Text(tab.title)
                        .font(Typography.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.eight)
                        .background(
                            scope == tab
                            ? DesignColor.accentColor.opacity(OpacityToken.p0_15)
                            : DesignColor.clear
                        )
                        .cornerRadius(CornerRadius.ten)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(tab.title))
                .accessibilityValue(
                    scope == tab ? Text(VoiceOver.A11y.selected) : Text("")
                )
            }
        }
        .padding(Spacing.eight)
        .background(DesignColor.groupedSecondary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.fourteen))
        .padding(.horizontal, Spacing.system)
        .padding(.top, Spacing.four)
    }
}
