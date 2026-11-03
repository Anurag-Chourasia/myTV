//
//  SkeletonRow.swift
//  myTV
//
//  Created by Anurag Chourasia on 23/01/26.
//

import SwiftUI
import DesignTokensKit

struct SkeletonRow: View {
    var body: some View {
        VStack(alignment: .leading, spacing: \.eight) {
            RoundedRectangle(cornerRadius: \.four)
                .fill(\.gray, opacity: \.p0_3)
                .frame(height: \.p16)

            RoundedRectangle(cornerRadius: \.four)
                .fill(\.gray, opacity: \.p0_2)
                .frame(width: \.p80, height: \.p12)
        }
        .redacted(reason: .placeholder)
    }
}
