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

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                ChannelLogo(url: channel.logoURL, height: 64, width: 90)
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
            .frame(width: 110)
            .frame(minHeight: 110)

            FavoriteButton(isFavorite: isFavorite, action: onFavoriteToggle)
        }
        .frame(width: 120)
        .frame(minHeight: 120)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
