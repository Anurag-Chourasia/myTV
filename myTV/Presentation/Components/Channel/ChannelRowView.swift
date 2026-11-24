//
//  ChannelRowView.swift
//  myTV
//
//  Created by Anurag Chourasia on 24/01/26.
//


import SwiftUI
import LocalizationKit
import DesignTokensKit
import UIComponentsKit

struct ChannelRowView: View {
    let channel: Channel
    let isFavorite: Bool
    let onFavoriteToggle: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        CatalogTile(layout: .list, metrics: themedMetrics,
                    colors: SemanticColors(surface: \.surface, border: \.border)) {
            ChannelLogo(url: channel.logoURL, height: DesignMetric.p48, width: DesignMetric.p64)
        } details: {
            VStack(alignment: .leading, spacing: \.four) {
                let titleLimit = dynamicTypeSize.isAccessibilitySize
                    ? CatalogMetrics.accessibleTitleLines : CatalogMetrics.listTitleLines
                Text(channel.name)
                    .font(\.headline)
                    .foregroundColor(\.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(titleLimit)
                if channel.hasStreams == false {
                    Text(\.channelStreamsUnavailable)
                        .font(\.caption)
                        .foregroundColor(\.secondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        } accessory: {
            FavoriteButton(isFavorite: isFavorite, action: onFavoriteToggle)
        }
    }

    private var themedMetrics: CatalogTileMetrics {
        var metrics = CatalogTileMetrics.plainRow
        metrics.surface = LayoutPreset.compact.card
        metrics.spacing = LayoutPreset.compact.itemSpacing
        return metrics
    }
}
