//
//  SkeletonListView.swift
//  myTV
//
//  Created by Anurag Chourasia on 23/01/26.
//

import SwiftUI
import DesignTokensKit

struct SkeletonListView: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: LayoutPreset.compact.itemSpacing) {
                ForEach(0..<6, id: \.self) { _ in
                    SkeletonRow()
                }
            }
            .padding(.all, LayoutPreset.compact.screenInset)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(\.background)
    }
}
