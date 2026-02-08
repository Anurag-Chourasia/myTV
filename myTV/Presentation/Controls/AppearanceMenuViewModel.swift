//
//  AppearanceMenuViewModel.swift
//  myTV
//
//  Created by Anurag Chourasia on 08/02/26.
//

import Foundation

struct AppearanceMenuViewModel {
    let menuTitle: String

    init(menuTitle: String = Localizable.Channel.Menu.Section.appearance) {
        self.menuTitle = menuTitle
    }

    func title(for appearance: AppAppearance) -> String {
        switch appearance {
        case .system:
            return Localizable.App.Appearance.Color.system
        case .light:
            return Localizable.App.Appearance.Color.light
        case .dark:
            return Localizable.App.Appearance.Color.dark
        }
    }
}
