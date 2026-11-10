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
                surface: LayoutPreset.compact.card,
                button: LayoutPreset.compact.button,
                colors: SemanticColors(surface: \.surface, border: \.border, action: \.action, onAction: \.onAction)))
            .environment(\.designTokens, DesignTokensTheme(brand: .myTV))
            .tint(\.action)
            .appAppearance()
            .dynamicTypeSize(.xSmall ... .accessibility2)
        }
    }
}
