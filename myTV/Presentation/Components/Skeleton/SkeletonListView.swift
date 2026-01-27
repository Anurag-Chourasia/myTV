//
//  SkeletonListView.swift
//  myTV
//
//  Created by Anurag Chourasia on 23/01/26.
//

import SwiftUI

struct SkeletonListView: View {
    var body: some View {
        List(0..<4, id: \.self) { _ in
            SkeletonRow()
        }
    }
}
