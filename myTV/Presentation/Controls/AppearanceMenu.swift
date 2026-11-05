//
//  AppAppearance.swift
//  myTV
//
//  Created by Anurag Chourasia on 23/01/26.
//

import SwiftUI
import DesignTokensKit
import LocalizationKit
import UIComponentsKit

private struct ScreenTools: ViewModifier {
    @State private var developerPresented = false
    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        AppearanceMenu(title: String(\MyTVStrings.appearanceMenuTitle), systemTitle: String(\MyTVStrings.appearanceSystem), lightTitle: String(\MyTVStrings.appearanceLight), darkTitle: String(\MyTVStrings.appearanceDark), onSelection: { AppDI.shared.getHaptics().selection() })
                        Button { developerPresented = true } label: {
                            Label(Text(\.knowYourDeveloper), \.personCropCircle)
                        }
                    } label: { Label(Text(\.appOptions), \.line3Horizontal) }
                    .labelStyle(.iconOnly)
                    .tint(Color("BrandAction"))
                    .accessibilityIdentifier(.screenTools)
                }
            }
            .sheet(isPresented: $developerPresented) {
                NavigationStack {
                    AboutView(viewModel: AppDI.shared.makeAboutViewModel())
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button { developerPresented = false } label: { Image(\.close) }
                                    .accessibilityLabel(\.developerCloseProfile)
                            }
                        }
                }
            }
    }
}

extension View {
    func screenTools() -> some View { modifier(ScreenTools()) }
}
