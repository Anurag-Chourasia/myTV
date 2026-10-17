//
//  myTVApp.swift
//  myTV
//
//  Created by Anurag Chourasia on 23/01/26.
//

import SwiftUI

@main
struct myTVApp: App {

    var body: some Scene {
        WindowGroup {
            TVLaunchView()
            .appAppearance()
            .dynamicTypeSize(.xSmall ... .accessibility2)
        }
    }
}
