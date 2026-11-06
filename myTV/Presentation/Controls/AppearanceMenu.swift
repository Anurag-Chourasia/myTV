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

struct ScreenTools: ViewModifier {
    @State private var developerPresented = false
    var haptics: HapticService = AppDI.shared.getHaptics()
    var makeAboutViewModel: () -> AboutViewModel = { AppDI.shared.makeAboutViewModel() }

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        AppearanceMenu(title: String(\MyTVStrings.appearanceMenuTitle), systemTitle: String(\MyTVStrings.appearanceSystem), lightTitle: String(\MyTVStrings.appearanceLight), darkTitle: String(\MyTVStrings.appearanceDark), onSelection: { haptics.selection() })
                        Button { developerPresented = true } label: {
                            Label(Text(\.knowYourDeveloper), \.personCropCircle)
                        }
                    } label: { Label(Text(\.appOptions), \.line3Horizontal) }
                    .labelStyle(.iconOnly)
                    .tint(\.action)
                    .accessibilityIdentifier(.screenTools)
                }
            }
            .sheet(isPresented: $developerPresented) {
                NavigationStack {
                    AboutView(viewModel: makeAboutViewModel())
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
    func screenTools(
        haptics: HapticService? = nil,
        makeAboutViewModel: (() -> AboutViewModel)? = nil
    ) -> some View {
        modifier(
            ScreenTools(
                haptics: haptics ?? AppDI.shared.getHaptics(),
                makeAboutViewModel: makeAboutViewModel ?? { AppDI.shared.makeAboutViewModel() }
            )
        )
    }
}
