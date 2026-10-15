//
//  ChannelLogo.swift
//  myTV
//
//  Created by Anurag Chourasia on 25/01/26.
//

import SwiftUI
import DesignTokensKit

struct ChannelLogo: View {
    let url: URL?
    var height: CGFloat = DesignMetric.p40
    var width: CGFloat = DesignMetric.p40

    var body: some View {
        CachedAsyncImage(url: url) {
            ZStack {
                DesignColor.grouped

                Image(systemName: "tv")
                    .foregroundColor(DesignColor.secondary)
            }
        }
        .scaledToFit()
        .frame(width: width, height: height)
        .background(DesignColor.grouped)
        .cornerRadius(CornerRadius.six)
        .accessibilityHidden(true)
    }
}
