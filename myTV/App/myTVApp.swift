//
//  myTVApp.swift
//  myTV
//
//  Created by Anurag Chourasia on 23/01/26.
//

import SwiftUI

@main
struct myTVApp: App {
    @StateObject private var channels = AppDI.shared.makeChannelListViewModel()

    var body: some Scene {
        WindowGroup {
            ChannelListView(
                viewModel: channels
            )
            .appAppearance()
            .dynamicTypeSize(.xSmall ... .accessibility2)
        }
    }
}
