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
        VStack(alignment: .leading, spacing: Spacing.eight) {
            RoundedRectangle(cornerRadius: CornerRadius.four)
                .fill(Color.gray.opacity(0.3))
                .frame(height: 16)

            RoundedRectangle(cornerRadius: CornerRadius.four)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 80, height: 12)
        }
        .redacted(reason: .placeholder)
    }
}
