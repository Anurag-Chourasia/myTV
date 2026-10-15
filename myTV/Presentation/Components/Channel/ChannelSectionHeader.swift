import DesignTokensKit
//
//  ChannelSectionHeader.swift
//  myTV
//
//  Created by Anurag Chourasia on 26/01/26.
//


import SwiftUI

struct ChannelSectionHeader: View {

    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(Typography.headline)
                .fontWeight(.semibold)
                .foregroundStyle(DesignColor.secondary)
            Spacer()
        }
        .padding(.horizontal, Spacing.system)
        .background(DesignColor.clear)
    }
}
