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

    var icon: String {
        switch self {
        case .list: return "list.bullet"
        case .grid: return "square.grid.2x2"
        }
    }
}

struct LayoutSwitchMenu: View {

    let selectedLayout: ChannelLayout
    let onSelectLayout: (ChannelLayout) -> Void
    let onGridUnavailable: () -> Void
    let isAccessibilitySize: Bool
    let menuTitle: String
    let titleForLayout: (ChannelLayout) -> String

    init(
        selectedLayout: ChannelLayout,
        onSelectLayout: @escaping (ChannelLayout) -> Void,
        onGridUnavailable: @escaping () -> Void = {},
        isAccessibilitySize: Bool = false,
        menuTitle: String,
        titleForLayout: @escaping (ChannelLayout) -> String
    ) {
        self.selectedLayout = selectedLayout
        self.onSelectLayout = onSelectLayout
        self.onGridUnavailable = onGridUnavailable
        self.isAccessibilitySize = isAccessibilitySize
        self.menuTitle = menuTitle
        self.titleForLayout = titleForLayout
    }

    var body: some View {
        Menu {
            ForEach(ChannelLayout.allCases) { option in
                Button {
                    if option == .grid && isAccessibilitySize {
                        onGridUnavailable()
                        return
                    }
                    onSelectLayout(option)
                } label: {
                    Label(
                        titleForLayout(option),
                        systemImage: selectedLayout == option ? "checkmark" : option.icon
                    )
                }
            }
        } label: {
            Label(menuTitle, systemImage: selectedLayout.icon)
        }
    }
}
