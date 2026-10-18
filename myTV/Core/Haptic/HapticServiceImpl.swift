//
//  HapticServiceImpl.swift
//  myTV
//
//  Created by Anurag Chourasia on 24/01/26.
//

import UIKit

final class HapticServiceImpl: HapticService {

    func selection() {
        guard AppRuntime.hapticsEnabled, !UIAccessibility.isReduceMotionEnabled else { return }
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }

    func impact(_ style: ImpactStyle) {
        guard AppRuntime.hapticsEnabled, !UIAccessibility.isReduceMotionEnabled else { return }

        let generator = UIImpactFeedbackGenerator(
            style: style.uiKitStyle
        )
        generator.prepare()
        generator.impactOccurred()
    }

    func notification(_ type: NotificationType) {
        guard AppRuntime.hapticsEnabled, !UIAccessibility.isReduceMotionEnabled else { return }

        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type.uiKitType)
    }
}

private extension ImpactStyle {
    var uiKitStyle: UIImpactFeedbackGenerator.FeedbackStyle {
        switch self {
        case .light: return .light
        case .medium: return .medium
        case .heavy: return .heavy
        }
    }
}

private extension NotificationType {
    var uiKitType: UINotificationFeedbackGenerator.FeedbackType {
        switch self {
        case .success: return .success
        case .warning: return .warning
        case .error: return .error
        }
    }
}
