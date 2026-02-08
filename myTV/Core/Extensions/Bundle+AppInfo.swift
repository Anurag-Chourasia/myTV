//
//  Bundle+AppInfo.swift
//  myTV
//
//  Created by Anurag Chourasia on 08/02/26.
//

import Foundation

extension Bundle {
    var appVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var buildNumber: String {
        infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}
