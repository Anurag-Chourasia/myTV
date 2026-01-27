//
//  AppAppearance.swift
//  myTV
//
//  Created by Anurag Chourasia on 23/01/26.
//

import SwiftUI

enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return L10n.App.Appearance.Color.system
        case .light: return L10n.App.Appearance.Color.light
        case .dark: return L10n.App.Appearance.Color.dark
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

struct AppearanceMenu: View {

    @AppStorage("appAppearance") private var appAppearance: AppAppearance = .system

    private let haptics: HapticService = AppDI.shared.getHaptics()

    var body: some View {
        Menu {
            ForEach(AppAppearance.allCases) { appearance in
                Button {
                    guard appAppearance != appearance else { return }
                    appAppearance = appearance
                    haptics.selection()
                } label: {
                    if appAppearance == appearance {
                        Label(appearance.title, systemImage: "checkmark")
                    } else {
                        Text(appearance.title)
                    }
                }
            }
        } label: {
            Label("Appearance", systemImage: "circle.lefthalf.filled")
        }
    }
}
