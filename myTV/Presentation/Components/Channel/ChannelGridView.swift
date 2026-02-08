//
//  ChannelGridView.swift
//  myTV
//
//  Created by Anurag Chourasia on 25/01/26.
//


import SwiftUI

struct ChannelGridView: View {
    let channel: Channel
    let isFavorite: Bool
    let onFavoriteToggle: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                ChannelLogo(url: channel.logoURL, height: logoSize.height, width: logoSize.width)
                    .padding(.vertical, 10)
                Spacer(minLength: 0)
                Text(channel.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.bottom, 10)
                Spacer(minLength: 0)
            }
            .frame(width: contentWidth)
            .frame(minHeight: contentMinHeight)

            FavoriteButton(isFavorite: isFavorite, action: onFavoriteToggle)
        }
        .frame(width: cardWidth)
        .frame(minHeight: cardMinHeight)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private extension ChannelGridView {
    var isAccessibilitySize: Bool { dynamicTypeSize.isAccessibilitySize }

    var logoSize: CGSize {
        isAccessibilitySize
        ? CGSize(width: 120, height: 80)
        : CGSize(width: 90, height: 64)
    }

    var contentWidth: CGFloat { isAccessibilitySize ? 150 : 110 }
    var contentMinHeight: CGFloat { isAccessibilitySize ? 150 : 110 }

    var cardWidth: CGFloat { isAccessibilitySize ? 160 : 120 }
    var cardMinHeight: CGFloat { isAccessibilitySize ? 170 : 120 }
}
