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
        CatalogTile(layout: .list, metrics: .plainRow) {
            ChannelLogo(url: channel.logoURL)
        } details: {
            VStack(alignment: .leading, spacing: \.four) {
                Text(channel.name)
                    .font(Typography.headline)
                    .multilineTextAlignment(.leading)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? CatalogMetrics.accessibleTitleLines : CatalogMetrics.listTitleLines)
                if channel.hasStreams == false {
                    Text(\.channelStreamsUnavailable)
                        .font(Typography.caption)
                        .foregroundColor(\.secondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, \.eight)
        } accessory: {
            FavoriteButton(isFavorite: isFavorite, action: onFavoriteToggle)
        }
    }
}
