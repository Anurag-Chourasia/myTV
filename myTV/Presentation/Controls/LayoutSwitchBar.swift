//
//  LayoutSwitchBar.swift
//  myTV
//
//  Created by Anurag Chourasia on 25/01/26.
//

import SwiftUI
import UIComponentsKit

typealias ChannelLayout = CatalogLayout

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
        CatalogLayoutMenu(selection: selectedLayout, isAccessibilitySize: isAccessibilitySize,
                          title: menuTitle, titleForLayout: titleForLayout,
                          onSelect: onSelectLayout, onGridUnavailable: onGridUnavailable)
    }
}
