//
//  ChannelGridView.swift
//  myTV
//
//  Created by Anurag Chourasia on 25/01/26.
//


import SwiftUI
import LocalizationKit
import DesignTokensKit
import UIComponentsKit

struct ChannelGridView: View {
    let channel: Channel
    let isFavorite: Bool
    let onFavoriteToggle: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        CatalogTile(layout: .grid, metrics: themedMetrics,
                    colors: SemanticColors(surface: \.surface, border: \.border)) {
            ChannelLogo(url: channel.logoURL, height: logoSize.height, width: logoSize.width)
        } details: {
            VStack(alignment: .center, spacing: \.four) {
                Text(channel.name)
                    .font(\.headline)
                    .foregroundColor(\.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(CatalogMetrics.gridTitleLines)
                if channel.hasStreams == false {
                    Text(\.channelStreamsUnavailable)
                        .font(\.caption)
                        .foregroundColor(\.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        } accessory: {
            FavoriteButton(isFavorite: isFavorite, action: onFavoriteToggle)
        }
    }

    private var themedMetrics: CatalogTileMetrics {
        var metrics = CatalogTileMetrics.compactGrid(accessibility: dynamicTypeSize.isAccessibilitySize)
        metrics.surface.cornerRadius = LayoutPreset.compact.cardRadius
        metrics.surface.borderWidth = LayoutPreset.compact.borderWidth
        return metrics
    }

    private var logoSize: CGSize {
        dynamicTypeSize.isAccessibilitySize ? CatalogMetrics.accessibleLogoSize : CatalogMetrics.compactLogoSize
    }
}
