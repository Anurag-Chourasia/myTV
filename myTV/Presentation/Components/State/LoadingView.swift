//
//  LoadingView.swift
//  myTV
//
//  Created by Anurag Chourasia on 23/01/26.
//

import SwiftUI

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                ProgressView()
                Text(L10n.Loading.Preparing.stream)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .padding(20)
            .background(.ultraThinMaterial)
            .cornerRadius(12)
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(edges: .all)
    }
}
