//
//  LayoutSwitchBar.swift
//  myTV
//
//  Created by Anurag Chourasia on 25/01/26.
//

import SwiftUI

enum ChannelLayout: String, CaseIterable, Identifiable {
    case list
    case grid

    var id: String { rawValue }

    var title: String {
        switch self {
        case .list: return L10n.Channel.Layout.list
        case .grid: return L10n.Channel.Layout.grid
        }
    }

    var icon: String {
        switch self {
        case .list: return "list.bullet"
        case .grid: return "square.grid.2x2"
        }
    }
}

struct LayoutSwitchMenu: View {

    @AppStorage("channelLayout")
    private var layout: ChannelLayout = .list

    private let haptics = AppDI.shared.getHaptics()

    var body: some View {
        Menu {
            ForEach(ChannelLayout.allCases) { option in
                Button {
                    guard layout != option else { return }
                    layout = option
                    haptics.selection()
                } label: {
                    Label(
                        option.title,
                        systemImage: layout == option ? "checkmark" : option.icon
                    )
                }
            }
        } label: {
            Label(L10n.Channel.Layout.title, systemImage: layout.icon)
        }
    }
}
