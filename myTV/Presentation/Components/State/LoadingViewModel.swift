//
//  LoadingViewModel.swift
//  myTV
//
//  Created by Anurag Chourasia on 08/02/26.
//

import Foundation

struct LoadingViewModel {
    let message: String

    static var streamPreparationDefault: LoadingViewModel {
        LoadingViewModel(message: Localizable.Loading.Preparing.stream)
    }
}
