import LocalizationKit
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
            selectedLabel: String(\MyTVStrings.a11yFavoriteRemove),
            unselectedLabel: String(\MyTVStrings.a11yFavoriteAdd),
            action: action
        ) {
            Image(isFavorite ? \.heartFill : \.heart)
                .foregroundColor(isFavorite ? \.red : \.secondary)
        }
        .frame(width: \.p24, height: \.p24)
        .scaleEffect(isFavorite ? ScaleToken.p1_15 : ScaleToken.p1_0)
        .accessibilityHint(Text(String(\MyTVStrings.a11yFavoriteHint)))
    }
}
