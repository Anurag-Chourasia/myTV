//
//  ChannelGridView.swift
//  myTV
//
//  Created by Anurag Chourasia on 25/01/26.
//


import SwiftUI
import DesignTokensKit
import UIComponentsKit

struct ChannelGridView: View {
    let channel: Channel
    let isFavorite: Bool
    let onFavoriteToggle: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        CatalogTile(layout: .grid, metrics: .compactGrid(accessibility: dynamicTypeSize.isAccessibilitySize),
                    colors: SemanticColors(surface: DesignColor.groupedSecondary)) {
            ChannelLogo(url: channel.logoURL, height: logoSize.height, width: logoSize.width)
        } details: {
            Text(channel.name)
                .font(Typography.headline)
                .foregroundColor(DesignColor.primary)
                .multilineTextAlignment(.center)
                .lineLimit(CatalogMetrics.gridTitleLines)
        } accessory: {
            FavoriteButton(isFavorite: isFavorite, action: onFavoriteToggle)
        }
    }

    private var logoSize: CGSize {
        dynamicTypeSize.isAccessibilitySize ? CatalogMetrics.accessibleLogoSize : CatalogMetrics.compactLogoSize
    }
}
