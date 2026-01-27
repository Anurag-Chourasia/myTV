//
//  ChannelLogo.swift
//  myTV
//
//  Created by Anurag Chourasia on 25/01/26.
//

import SwiftUI

struct ChannelLogo: View {
    let url: URL?
    var height: CGFloat = 40
    var width: CGFloat = 40

    var body: some View {
        CachedAsyncImage(url: url) {
            ZStack {
                Color(UIColor.systemGroupedBackground)

                Image(systemName: "tv")
                    .foregroundColor(.secondary)
            }
        }
        .scaledToFit()
        .frame(width: width, height: height)
        .background(Color(UIColor.systemGroupedBackground))
        .cornerRadius(6)
    }
}
