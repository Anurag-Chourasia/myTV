import LocalizationKit
import UIComponentsKit
//
//  AppearanceMenuViewModel.swift
//  myTV
//
//  Created by Anurag Chourasia on 08/02/26.
//

import Foundation

struct AppearanceMenuViewModel {
    let menuTitle: String

    init(menuTitle: String = String(\MyTVStrings.appearanceMenuTitle)) {
        self.menuTitle = menuTitle
    }

    func title(for appearance: AppAppearance) -> String {
        switch appearance {
        case .system:
            return String(\MyTVStrings.appearanceSystem)
        case .light:
            return String(\MyTVStrings.appearanceLight)
        case .dark:
            return String(\MyTVStrings.appearanceDark)
        }
    }
}
