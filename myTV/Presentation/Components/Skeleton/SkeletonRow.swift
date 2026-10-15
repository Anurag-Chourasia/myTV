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
                .fill(DesignColor.gray.opacity(OpacityToken.p0_3))
                .frame(height: DesignMetric.p16)

            RoundedRectangle(cornerRadius: CornerRadius.four)
                .fill(DesignColor.gray.opacity(OpacityToken.p0_2))
                .frame(width: DesignMetric.p80, height: DesignMetric.p12)
        }
        .redacted(reason: .placeholder)
    }
}
