//
//  ChannelRowView.swift
//  myTV
//
//  Created by Anurag Chourasia on 24/01/26.
//


import SwiftUI
import DesignTokensKit

struct ChannelRowView: View {
    let channel: Channel
    let isFavorite: Bool
    let onFavoriteToggle: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(spacing: Spacing.twelve) {
            ChannelLogo(url: channel.logoURL)

            Text(channel.name)
                .font(.headline)
                .multilineTextAlignment(.leading)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 2)
                .padding(.horizontal, Spacing.eight)

            Spacer(minLength: 0)

            FavoriteButton(isFavorite: isFavorite, action: onFavoriteToggle)
        }
    }
}
