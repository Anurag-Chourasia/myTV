import SwiftUI
import AuthKit
import LocalizationKit
import DesignTokensKit
import UIComponentsKit

struct UserSettingsView: View {
    let user: AuthUser?
    let sessionManager: SessionManager?
    let appName: String
    let disclaimerText: String
    let makeAboutViewModel: () -> AboutViewModel
    let onDismiss: () -> Void

    @State private var showingDeleteConfirmation = false
    @State private var showingDeveloperProfile = false

    var body: some View {
        NavigationStack {
            Form {
                UserSettingsAccountSection(
                    user: user,
                    isLoading: sessionManager?.isLoading ?? false,
                    onSignOut: {
                        Task {
                            await sessionManager?.signOut()
                            onDismiss()
                        }
                    },
                    onDeleteAccount: {
                        showingDeleteConfirmation = true
                    }
                )

                UserSettingsAboutSection(
                    appName: appName,
                    version: AppRuntime.version,
                    build: AppRuntime.build,
                    disclaimerText: disclaimerText,
                    onOpenDeveloperProfile: {
                        showingDeveloperProfile = true
                    }
                )
            }
            .navigationTitle(String(\CommonStrings.accountTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(\CommonStrings.done)) {
                        onDismiss()
                    }
                }
            }
            .confirmationDialog(
                String(\CommonStrings.accountDeleteConfirmationTitle),
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button(String(\CommonStrings.accountDeleteConfirmationAction), role: .destructive) {
                    Task {
                        await sessionManager?.deleteAccount()
                        onDismiss()
                    }
                }
                Button(String(\CommonStrings.cancel), role: .cancel) {}
            } message: {
                Text(String(\CommonStrings.accountDeleteConfirmationMessage))
            }
            .sheet(isPresented: $showingDeveloperProfile) {
                NavigationStack {
                    AboutView(viewModel: makeAboutViewModel())
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button {
                                    showingDeveloperProfile = false
                                } label: {
                                    Image(\.close)
                                }
                                .accessibilityLabel(\.developerCloseProfile)
                            }
                        }
                }
            }
        }
    }
}
