//
//  myTVApp.swift
//  myTV
//
//  Created by Anurag Chourasia on 23/01/26.
//

import SwiftUI
import DesignTokensKit
import UIComponentsKit

@main
struct myTVApp: App {

    var body: some Scene {
        WindowGroup {
            TVLaunchView()
            .componentTheme(ComponentTheme(
                surface: LayoutPreset.compactMedia.card,
                button: LayoutPreset.compactMedia.button,
                colors: SemanticColors(palette: BrandPalette.myTV)))
            .environment(\.designTokens, DesignTokensTheme(brand: .myTV))
            .tint(\.action)
            .appAppearance()
            .dynamicTypeSize(.xSmall ... .accessibility2)
        }
    }
}
