//
//  ChannelStickyBar.swift
//  myTV
//
//  Created by Anurag Chourasia on 25/01/26.
//

import SwiftUI

struct ChannelStickyBar: View {

    @Binding var scope: ChannelListViewModel.ChannelScope

    var body: some View {
        HStack(spacing: 8) {
            ForEach(ChannelListViewModel.ChannelScope.allCases) { tab in
                Button {
                    scope = tab
                } label: {
                    Text(tab.title)
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            scope == tab
                            ? Color.accentColor.opacity(0.15)
                            : Color.clear
                        )
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(tab.title))
                .accessibilityValue(
                    scope == tab ? Text(VoiceOver.A11y.selected) : Text("")
                )
            }
        }
        .padding(8)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
        .padding(.top, 4)
    }
}
