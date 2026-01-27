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
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary) 
            Spacer()
        }
        .padding(.horizontal)
        .background(Color.clear)
    }
}
