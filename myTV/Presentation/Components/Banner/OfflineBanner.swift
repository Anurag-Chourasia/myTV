//
//  OfflineBanner.swift
//  myTV
//
//  Created by Anurag Chourasia on 23/01/26.
//

import SwiftUI

struct OfflineBanner: View {
    let viewModel: OfflineBannerViewModel

    var body: some View {
        HStack {
            Image(systemName: "wifi.slash")
                .accessibilityHidden(true)
            Text(viewModel.message)
        }
        .font(.caption)
        .foregroundColor(.white)
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(Color.red)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(viewModel.message))
    }
}
