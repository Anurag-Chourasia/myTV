import SwiftUI
import LocalizationKit
import DesignTokensKit

struct UserSettingsAboutSection: View {
    let appName: String
    let version: String
    let build: String
    let disclaimerText: String
    let onOpenDeveloperProfile: () -> Void

    private var versionDisplay: String {
        let prefix = String(\MyTVStrings.aboutAppVersionPrefix)
        return "\(prefix) \(version) (\(build))"
    }

    var body: some View {
        Section(String(\MyTVStrings.aboutAppInfoTitle)) {
            VStack(alignment: .leading, spacing: \.four) {
                Text(appName)
                    .font(\.headline)
                    .foregroundStyle(\.primary)
                Text(versionDisplay)
                    .font(\.subheadline)
                    .foregroundStyle(\.secondary)
            }
            .padding(.vertical, \.two)

            VStack(alignment: .leading, spacing: \.four) {
                Text(String(\MyTVStrings.aboutDisclaimerTitle))
                    .font(\.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(\.secondary)
                Text(disclaimerText)
                    .font(\.caption)
                    .foregroundStyle(\.secondary)
            }
            .padding(.vertical, \.two)

            Button(action: onOpenDeveloperProfile) {
                Label(String(\MyTVStrings.aboutTitle), \.infoCircle)
            }
        }
    }
}
