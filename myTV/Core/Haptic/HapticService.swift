//
//  HapticService.swift
//  myTV
//
//  Created by Anurag Chourasia on 24/01/26.
//


import UIKit

protocol HapticService {
    func selection()
    func impact(_ style: ImpactStyle)
    func notification(_ type: NotificationType)
}

enum ImpactStyle {
    case light
    case medium
    case heavy
}

enum NotificationType {
    case success
    case warning
    case error
}
