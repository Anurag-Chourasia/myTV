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
    private let viewModel: AppearanceMenuViewModel
    private let haptics: HapticService = AppDI.shared.getHaptics()

    init(viewModel: AppearanceMenuViewModel = AppearanceMenuViewModel()) {
        self.viewModel = viewModel
    }

    var body: some View {
        Menu {
            ForEach(AppAppearance.allCases) { appearance in
                Button {
                    guard appAppearance != appearance else { return }
                    appAppearance = appearance
                    haptics.selection()
                } label: {
                    if appAppearance == appearance {
                        Label(viewModel.title(for: appearance), systemImage: "checkmark")
                    } else {
                        Text(viewModel.title(for: appearance))
                    }
                }
            }
        } label: {
            Label(viewModel.menuTitle, systemImage: "circle.lefthalf.filled")
        }
    }
}
