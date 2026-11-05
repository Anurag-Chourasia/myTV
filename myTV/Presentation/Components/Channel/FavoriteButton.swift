import DesignTokensKit
//
//  FavoriteButton.swift
//  myTV
//
//  Created by Anurag Chourasia on 26/01/26.
//


import SwiftUI
import UIComponentsKit

struct FavoriteButton: View {
    let isFavorite: Bool
    let action: () -> Void
    
    var body: some View {
        SelectionToggleButton(
            isSelected: isFavorite,
            selectedLabel: VoiceOver.A11y.Favorite.remove,
            unselectedLabel: VoiceOver.A11y.Favorite.add,
            action: action
        ) {
            Image(isFavorite ? \.heartFill : \.heart)
                .foregroundColor(isFavorite ? \.red : \.secondary)
        }
        .frame(width: \.p24, height: \.p24)
        .scaleEffect(isFavorite ? ScaleToken.p1_15 : ScaleToken.p1_0)
        .accessibilityHint(Text(VoiceOver.A11y.Favorite.hint))
    }
}
