import XCTest
import Combine
@testable import AuthKit
@testable import myTV

@MainActor
final class AuthenticationLifecycleTests: XCTestCase {

    private final class MockLifecycleBackend: AuthBackend {
        var signedInUser: AuthUser?
        var shouldFailSignIn = false
        var shouldFailSignUp = false
        var shouldFailPasswordReset = false
        var shouldFailUpdatePassword = false
        var shouldFailCallback = false
        var shouldFailDeleteAccount = false
        var deleteAccountCallCount = 0
        var callbackHandledURLs: [URL] = []
        var updatedPasswords: [String] = []
        var resetRequestedEmails: [String] = []

        private let eventsSubject = PassthroughSubject<AuthSessionEvent, Never>()

        func signIn(email: String, password: String) async throws -> AuthUser {
            if shouldFailSignIn { throw URLError(.userAuthenticationRequired) }
            let user = AuthUser(id: UUID(), email: email)
            signedInUser = user
            eventsSubject.send(AuthSessionEvent(user: user, isPasswordRecovery: false))
            return user
        }

        func signUp(email: String, password: String) async throws -> Bool {
            if shouldFailSignUp { throw URLError(.cannotCreateFile) }
            return true // Confirmation email required
        }

        func currentUser() async throws -> AuthUser? {
            signedInUser
        }

        func refreshSession() async throws {
            if signedInUser == nil { throw URLError(.userAuthenticationRequired) }
        }

        func signOut() async throws {
            signedInUser = nil
            eventsSubject.send(AuthSessionEvent(user: nil, isPasswordRecovery: false))
        }

        func deleteAccount() async throws {
            if shouldFailDeleteAccount { throw URLError(.cannotRemoveFile) }
            deleteAccountCallCount += 1
            signedInUser = nil
            eventsSubject.send(AuthSessionEvent(user: nil, isPasswordRecovery: false))
        }

        func events() async -> AsyncStream<AuthSessionEvent> {
            AsyncStream { continuation in
                let cancellable = eventsSubject.sink { event in
                    continuation.yield(event)
                }
                continuation.onTermination = { _ in
                    cancellable.cancel()
                }
            }
        }

        func requestPasswordReset(email: String, redirectTo: URL) async throws {
            if shouldFailPasswordReset { throw URLError(.badServerResponse) }
            resetRequestedEmails.append(email)
        }

        func updatePassword(_ password: String) async throws {
            if shouldFailUpdatePassword { throw URLError(.cannotWriteToFile) }
            updatedPasswords.append(password)
        }

        func signIn(provider: AuthProvider, redirectTo: URL) async throws -> AuthUser {
            let user = AuthUser(id: UUID(), email: "oauth-\(provider.rawValue)@example.com")
            signedInUser = user
            eventsSubject.send(AuthSessionEvent(user: user, isPasswordRecovery: false))
            return user
        }

        func handleCallback(_ url: URL) async throws -> AuthUser {
            if shouldFailCallback { throw URLError(.badURL) }
            callbackHandledURLs.append(url)
            let user = AuthUser(id: UUID(), email: "recovered@example.com")
            signedInUser = user
            // If callback represents password recovery, emit recovery event
            let isRecovery = url.fragment?.contains("type=recovery") ?? false || url.query?.contains("type=recovery") ?? false
            eventsSubject.send(AuthSessionEvent(user: user, isPasswordRecovery: isRecovery))
            return user
        }
    }

    func testProductionAuthenticationDisabledByDefault() {
        XCTAssertFalse(
            Bundle.main.object(forInfoDictionaryKey: "AUTHKIT_ENABLED") as? Bool ?? false,
            "AUTHKIT_ENABLED must be strictly false in production Info.plist until all lifecycle gates pass"
        )
    }

    func testFullAuthenticationLifecycle() async throws {
        let backend = MockLifecycleBackend()
        let authService = AuthService(backend: backend)
        let session = SessionManager(authService: authService)

        // 1. Initial State: Unauthenticated after restore
        await session.restoreSession()
        XCTAssertEqual(session.state, .unauthenticated)
        XCTAssertFalse(session.isLoading)
        XCTAssertNil(session.errorMessage)

        // 2. Signup Flow (verification required notice)
        await session.signUp(email: "newuser@example.com", password: "Password123!")
        XCTAssertEqual(session.notice, "Check your email to confirm your account.")
        XCTAssertEqual(session.state, .unauthenticated)

        // 3. Email & Password Sign In
        await session.signIn(email: "streamer@mytv.test", password: "ValidPassword123!")
        guard case .authenticated(let user) = session.state else {
            XCTFail("Expected .authenticated state, got \(session.state)")
            return
        }
        XCTAssertEqual(user.email, "streamer@mytv.test")

        // 4. Relaunch / Session Restoration Simulation
        let relaunchedSession = SessionManager(authService: authService)
        await relaunchedSession.restoreSession()
        guard case .authenticated(let restoredUser) = relaunchedSession.state else {
            XCTFail("Expected restored .authenticated state, got \(relaunchedSession.state)")
            return
        }
        XCTAssertEqual(restoredUser.email, "streamer@mytv.test")

        // 5. OAuth Provider Sign In (Google & GitHub)
        let redirectURL = try XCTUnwrap(URL(string: "mytv-auth://auth/callback"))
        await session.signIn(provider: .google, redirectTo: redirectURL)
        guard case .authenticated(let googleUser) = session.state else {
            XCTFail("Expected .authenticated after Google sign-in")
            return
        }
        XCTAssertEqual(googleUser.email, "oauth-google@example.com")

        await session.signIn(provider: .github, redirectTo: redirectURL)
        guard case .authenticated(let githubUser) = session.state else {
            XCTFail("Expected .authenticated after GitHub sign-in")
            return
        }
        XCTAssertEqual(githubUser.email, "oauth-github@example.com")

        // 6. Local Sign Out
        await session.signOut()
        XCTAssertEqual(session.state, .unauthenticated)
        let signedOutUser = try await authService.currentUser()
        XCTAssertNil(signedOutUser)

        // 7. Password Recovery Request & Deep-Link Callback Handling
        await session.requestPasswordReset(email: "forgotten@mytv.test", redirectTo: redirectURL)
        XCTAssertEqual(session.notice, "If an account exists, a reset link will be sent to your email.")
        XCTAssertEqual(backend.resetRequestedEmails, ["forgotten@mytv.test"])

        // Deep-link arrives on requesting device
        let recoveryCallbackURL = try XCTUnwrap(URL(string: "mytv-auth://auth/callback#type=recovery&access_token=xyz"))
        await session.handleCallback(recoveryCallbackURL)
        XCTAssertTrue(backend.callbackHandledURLs.contains(recoveryCallbackURL))

        // Update password on requesting device
        await session.updatePassword("NewSecurePassword88!")
        XCTAssertEqual(backend.updatedPasswords, ["NewSecurePassword88!"])
        XCTAssertEqual(session.notice, "Your password has been updated.")
        XCTAssertFalse(session.isPasswordRecovery)

        // 8. Replay / Expired link rejection simulation
        backend.shouldFailCallback = true
        let replayedURL = try XCTUnwrap(URL(string: "mytv-auth://auth/callback#type=recovery&access_token=expired"))
        await session.handleCallback(replayedURL)
        XCTAssertNotNil(session.errorMessage, "Replayed or expired callback URL must set an error message")
    }

    func testDeleteAccountLifecycleSuccess() async throws {
        let backend = MockLifecycleBackend()
        let authService = AuthService(backend: backend)
        let session = SessionManager(authService: authService)

        await session.signIn(email: "deleteme@mytv.test", password: "Password123!")
        guard case .authenticated = session.state else {
            XCTFail("User should be authenticated before deletion")
            return
        }

        await session.deleteAccount()

        XCTAssertEqual(backend.deleteAccountCallCount, 1)
        XCTAssertEqual(session.state, .unauthenticated)
        XCTAssertEqual(session.notice, "Your account and associated cloud data have been deleted.")
        XCTAssertNil(session.errorMessage)

        let currentUser = try await authService.currentUser()
        XCTAssertNil(currentUser)
    }

    func testDeleteAccountFailureIsRecoverable() async throws {
        let backend = MockLifecycleBackend()
        let authService = AuthService(backend: backend)
        let session = SessionManager(authService: authService)

        await session.signIn(email: "recoverable@mytv.test", password: "Password123!")
        guard case .authenticated = session.state else {
            XCTFail("User should be authenticated before deletion")
            return
        }

        // Trigger failure
        backend.shouldFailDeleteAccount = true
        await session.deleteAccount()

        XCTAssertNotNil(session.errorMessage)
        guard case .authenticated = session.state else {
            XCTFail("State must remain authenticated on failure to allow retry")
            return
        }

        // Clear failure and retry
        backend.shouldFailDeleteAccount = false
        await session.deleteAccount()

        XCTAssertNil(session.errorMessage)
        XCTAssertEqual(session.state, .unauthenticated)
        XCTAssertEqual(session.notice, "Your account and associated cloud data have been deleted.")
        XCTAssertEqual(backend.deleteAccountCallCount, 1)
    }
}
