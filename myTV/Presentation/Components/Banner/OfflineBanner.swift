import DesignTokensKit
//
//  OfflineBanner.swift
//  myTV
//
//  Created by Anurag Chourasia on 23/01/26.
//

import SwiftUI
import UIComponentsKit

struct OfflineBanner: View {
    let viewModel: OfflineBannerViewModel

    var body: some View {
        IconMessageBanner(foreground: DesignColor.white) {
            Image(systemName: "wifi.slash")
        } message: {
            Text(viewModel.message)
        } background: {
            DesignColor.red
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(viewModel.message))
    }
}
