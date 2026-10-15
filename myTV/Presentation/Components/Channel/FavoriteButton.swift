import DesignTokensKit
//
//  FavoriteButton.swift
//  myTV
//
//  Created by Anurag Chourasia on 26/01/26.
//


import SwiftUI

struct FavoriteButton: View {
    let isFavorite: Bool
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .foregroundColor(isFavorite ? DesignColor.red : DesignColor.secondary)
        }
        .buttonStyle(.plain)
        .frame(width: DesignMetric.p24, height: DesignMetric.p24)
        .scaleEffect(isFavorite ? ScaleToken.p1_15 : ScaleToken.p1_0)
        .accessibilityLabel(
            Text(isFavorite ? VoiceOver.A11y.Favorite.remove : VoiceOver.A11y.Favorite.add)
        )
        .accessibilityHint(Text(VoiceOver.A11y.Favorite.hint))
    }
}
