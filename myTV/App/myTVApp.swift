//
//  myTVApp.swift
//  myTV
//
//  Created by Anurag Chourasia on 23/01/26.
//

import SwiftUI


@main
struct myTVApp: App {
    @AppStorage("appAppearance") private var appAppearance: AppAppearance = .system

    var body: some Scene {
        WindowGroup {
            ChannelListView(
                viewModel: AppDI.shared.makeChannelListViewModel()
            )
            .preferredColorScheme(appAppearance.colorScheme)
        }
    }
}
