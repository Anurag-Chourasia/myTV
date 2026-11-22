import XCTest
import SwiftUI
@testable import AuthKit
@testable import myTV

@MainActor
final class UserSettingsViewTests: XCTestCase {

    private final class MockAuthBackend: AuthBackend {
        var signedInUser: AuthUser?
        var signOutCalled = false
        var deleteAccountCalled = false

        init(user: AuthUser?) {
            self.signedInUser = user
        }

        func signIn(email: String, password: String) async throws -> AuthUser {
            let user = AuthUser(id: UUID(), email: email)
            signedInUser = user
            return user
        }

        func signUp(email: String, password: String) async throws -> Bool { true }
        func currentUser() async throws -> AuthUser? { signedInUser }
        func refreshSession() async throws {}
        func events() async -> AsyncStream<AuthSessionEvent> { AsyncStream { $0.finish() } }
        func requestPasswordReset(email: String, redirectTo: URL) async throws {}
        func updatePassword(_ password: String) async throws {}
        func signIn(provider: AuthProvider, redirectTo: URL) async throws -> AuthUser {
            let user = AuthUser(id: UUID(), email: "oauth@example.com")
            signedInUser = user
            return user
        }
        func handleCallback(_ url: URL) async throws -> AuthUser {
            let user = AuthUser(id: UUID(), email: "callback@example.com")
            signedInUser = user
            return user
        }

        func signOut() async throws {
            signOutCalled = true
            signedInUser = nil
        }

        func deleteAccount() async throws {
            deleteAccountCalled = true
            signedInUser = nil
        }
    }

    func testUserSettingsViewRendersWithAuthenticatedUser() {
        let user = AuthUser(id: UUID(), email: "user@mytv.example")
        let backend = MockAuthBackend(user: user)
        let session = SessionManager(authService: AuthService(backend: backend))
        var dismissed = false

        let view = UserSettingsView(
            user: user,
            sessionManager: session,
            appName: "myTV",
            disclaimerText: "Streaming disclaimer",
            makeAboutViewModel: { AppDI.shared.makeAboutViewModel() },
            onDismiss: { dismissed = true }
        )

        let hosting = UIHostingController(rootView: view)
        hosting.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        hosting.view.layoutIfNeeded()

        XCTAssertNotNil(hosting.view)
        XCTAssertGreaterThan(hosting.view.frame.width, 0)
        XCTAssertFalse(dismissed)
    }

    func testUserSettingsViewRendersInGuestMode() {
        var dismissed = false

        let view = UserSettingsView(
            user: nil,
            sessionManager: nil,
            appName: "myTV",
            disclaimerText: "Streaming disclaimer",
            makeAboutViewModel: { AppDI.shared.makeAboutViewModel() },
            onDismiss: { dismissed = true }
        )

        let hosting = UIHostingController(rootView: view)
        hosting.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        hosting.view.layoutIfNeeded()

        XCTAssertNotNil(hosting.view)
        XCTAssertGreaterThan(hosting.view.frame.width, 0)
        XCTAssertFalse(dismissed)
    }

    func testChannelListViewAcceptsUserAndSessionManager() {
        let user = AuthUser(id: UUID(), email: "user@mytv.example")
        let backend = MockAuthBackend(user: user)
        let session = SessionManager(authService: AuthService(backend: backend))

        let viewModel = AppDI.shared.makeChannelListViewModel(ownerID: user.id)
        let view = ChannelListView(
            viewModel: viewModel,
            user: user,
            sessionManager: session
        )

        let hosting = UIHostingController(rootView: view)
        hosting.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        hosting.view.layoutIfNeeded()

        XCTAssertNotNil(hosting.view)
        XCTAssertGreaterThan(hosting.view.frame.width, 0)
    }

    func testUserSettingsSignOutAndAccountDeletion() async {
        let user = AuthUser(id: UUID(), email: "user@mytv.example")
        let backend = MockAuthBackend(user: user)
        let session = SessionManager(authService: AuthService(backend: backend))

        await session.signOut()
        XCTAssertTrue(backend.signOutCalled)
        XCTAssertNil(backend.signedInUser)

        backend.signedInUser = user
        await session.deleteAccount()
        XCTAssertTrue(backend.deleteAccountCalled)
        XCTAssertNil(backend.signedInUser)
    }
}
