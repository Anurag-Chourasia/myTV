//
//  ChannelRowView.swift
//  myTV
//
//  Created by Anurag Chourasia on 24/01/26.
//


import SwiftUI
import DesignTokensKit
import UIComponentsKit

struct ChannelRowView: View {
    let channel: Channel
    let isFavorite: Bool
    let onFavoriteToggle: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        CatalogTile(layout: .list, metrics: .plainRow) {
            ChannelLogo(url: channel.logoURL)
        } details: {
            Text(channel.name)
                .font(Typography.headline)
                .multilineTextAlignment(.leading)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? CatalogMetrics.accessibleTitleLines : CatalogMetrics.listTitleLines)
                .padding(.horizontal, Spacing.eight)
        } accessory: {
            FavoriteButton(isFavorite: isFavorite, action: onFavoriteToggle)
        }
    }
}
