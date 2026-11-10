import SwiftUI
import UIComponentsKit
import DesignTokensKit

struct OfflineBanner: View {
    let viewModel: OfflineBannerViewModel

    var body: some View {
        OfflineBannerView(
            message: viewModel.message,
            isWarning: true,
            backgroundColor: \.red
        )
    }
}
