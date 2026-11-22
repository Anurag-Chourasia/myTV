import SwiftUI
import AuthKit
import LocalizationKit
import DesignTokensKit

struct UserSettingsAccountSection: View {
    let user: AuthUser?
    let isLoading: Bool
    let onSignOut: () -> Void
    let onDeleteAccount: () -> Void

    var body: some View {
        Section(String(\CommonStrings.accountTitle)) {
            if let user {
                HStack(spacing: \.twelve) {
                    Image(\.personCropCircle)
                        .foregroundStyle(\.secondary)
                    Text(user.email ?? String(\CommonStrings.accountSignedIn))
                        .foregroundStyle(\.primary)
                }

                Button(role: .destructive, action: onSignOut) {
                    Label(String(\CommonStrings.authButtonSignOut), \.rectanglePortraitAndArrowRight)
                }
                .disabled(isLoading)

                Button(role: .destructive, action: onDeleteAccount) {
                    Label(String(\CommonStrings.authButtonDeleteAccount), \.trash)
                }
                .disabled(isLoading)
            } else {
                HStack(spacing: \.twelve) {
                    Image(\.personCropCircle)
                        .foregroundStyle(\.secondary)
                    Text(String(\CommonStrings.accountTitle))
                        .foregroundStyle(\.secondary)
                }
            }
        }
    }
}
