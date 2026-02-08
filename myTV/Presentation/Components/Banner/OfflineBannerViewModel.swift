//
//  OfflineBannerViewModel.swift
//  myTV
//
//  Created by Anurag Chourasia on 08/02/26.
//

import Foundation

struct OfflineBannerViewModel {
    let message: String

    static var `default`: OfflineBannerViewModel {
        OfflineBannerViewModel(message: Localizable.App.Offline.banner)
    }
}
