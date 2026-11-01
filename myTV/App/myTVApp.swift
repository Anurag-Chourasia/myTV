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
                colors: SemanticColors(surface: Color("BrandSurface"), foreground: Color("BrandText"),
                    border: Color("BrandBorder"), action: Color("BrandAction"), onAction: Color("BrandOnAction"))))
            .tint(Color("BrandAction"))
            .appAppearance()
            .dynamicTypeSize(.xSmall ... .accessibility2)
        }
    }
}
