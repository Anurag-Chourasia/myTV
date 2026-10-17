//
//  AppAppearance.swift
//  myTV
//
//  Created by Anurag Chourasia on 23/01/26.
//

import SwiftUI
import DesignTokensKit

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
        .tint(DesignColor.primary)
        .foregroundStyle(DesignColor.primary)
    }
}

/// Apply to this scene's window so navigation destinations and sheets inherit it.
/// `.unspecified` restores the current system style, including after an override.
private struct WindowAppearance: UIViewRepresentable {
    let style: UIUserInterfaceStyle
    func makeUIView(context: Context) -> AppearanceView { AppearanceView() }
    func updateUIView(_ view: AppearanceView, context: Context) { view.style = style }

    final class AppearanceView: UIView {
        var style: UIUserInterfaceStyle = .unspecified { didSet { apply() } }
        override func didMoveToWindow() { super.didMoveToWindow(); apply() }
        private func apply() {
            guard let window, window.overrideUserInterfaceStyle != style else { return }
            window.overrideUserInterfaceStyle = style
        }
    }
}

private struct AppAppearanceModifier: ViewModifier {
    @AppStorage("appAppearance") private var selection: AppAppearance = .system
    func body(content: Content) -> some View {
        content.background(WindowAppearance(style: selection.interfaceStyle).allowsHitTesting(false))
    }
}

extension AppAppearance {
    var interfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .system: return .unspecified
        case .light: return .light
        case .dark: return .dark
        }
    }
}

extension View {
    func appAppearance() -> some View { modifier(AppAppearanceModifier()) }
}

private struct ScreenTools: ViewModifier {
    @State private var developerPresented = false
    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        AppearanceMenu()
                        Button { developerPresented = true } label: {
                            Label("Know Your Developer", systemImage: "person.crop.circle")
                        }
                    } label: { Label("App options", systemImage: "line.3.horizontal") }
                    .tint(DesignColor.primary)
                    .accessibilityIdentifier("screen-tools")
                }
            }
            .sheet(isPresented: $developerPresented) {
                NavigationStack {
                    AboutView(viewModel: AppDI.shared.makeAboutViewModel())
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button { developerPresented = false } label: { Image(systemName: "xmark") }
                                    .accessibilityLabel("Close developer profile")
                            }
                        }
                }
            }
    }
}

extension View {
    func screenTools() -> some View { modifier(ScreenTools()) }
}
