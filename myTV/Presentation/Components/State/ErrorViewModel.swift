//
//  ErrorViewModel.swift
//  myTV
//
//  Created by Anurag Chourasia on 08/02/26.
//

import Foundation

struct ErrorViewModel {
    let title: String
    let retryTitle: String

    static var generic: ErrorViewModel {
        ErrorViewModel(
            title: Localizable.Error.Generic.title,
            retryTitle: Localizable.App.retry
        )
    }
}
