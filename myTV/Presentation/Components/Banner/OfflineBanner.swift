//
//  OfflineBanner.swift
//  myTV
//
//  Created by Anurag Chourasia on 23/01/26.
//

import SwiftUI

struct OfflineBanner: View {

    var body: some View {
        HStack {
            Image(systemName: "wifi.slash")
            Text(L10n.App.Offline.banner)
        }
        .font(.caption)
        .foregroundColor(.white)
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(Color.red)
    }
}
