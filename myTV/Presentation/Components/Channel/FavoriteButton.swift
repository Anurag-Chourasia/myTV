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
                .foregroundColor(isFavorite ? .red : .secondary)
        }
        .buttonStyle(.plain)
        .frame(width: 24, height: 24)
        .scaleEffect(isFavorite ? 1.15 : 1.0)
        .accessibilityLabel(
            Text(isFavorite ? VoiceOver.A11y.Favorite.remove : VoiceOver.A11y.Favorite.add)
        )
        .accessibilityHint(Text(VoiceOver.A11y.Favorite.hint))
    }
}
