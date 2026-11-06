import XCTest
import Combine
@testable import AuthKit
@testable import AuthKitUI
@testable import myTV

@MainActor
final class BackendAuthorizationAndRLSTests: XCTestCase {

    // MARK: - Multi-User Test Models & RLS Service Double

    private struct ProtectedUserRecord: Equatable {
        let id: String
        let userId: UUID
        var content: String
    }

    private enum RLSAuthorisationError: LocalizedError {
        case unauthenticated
        case permissionDenied

        var errorDescription: String? {
            switch self {
            case .unauthenticated: "User must be authenticated to access records"
            case .permissionDenied: "Row-Level Security: Permission denied for target record"
            }
        }
    }

    private final class MockRLSDatabaseBackend: AuthBackend {
        var activeUser: AuthUser?
        var records: [String: ProtectedUserRecord] = [:]
        var resetRequestCount = 0
        var shouldSimulateRateLimit = false

        private let eventsSubject = PassthroughSubject<AuthSessionEvent, Never>()

        func setCurrentUser(_ user: AuthUser?) {
            activeUser = user
            eventsSubject.send(AuthSessionEvent(user: user, isPasswordRecovery: false))
        }

        func signIn(email: String, password: String) async throws -> AuthUser {
            let user = AuthUser(id: UUID(), email: email)
            activeUser = user
            eventsSubject.send(AuthSessionEvent(user: user, isPasswordRecovery: false))
            return user
        }

        func signUp(email: String, password: String) async throws -> Bool {
            true // Requires email confirmation
        }

        func currentUser() async throws -> AuthUser? {
            activeUser
        }

        func refreshSession() async throws {
            if activeUser == nil {
                throw URLError(.userAuthenticationRequired)
            }
        }

        func signOut() async throws {
            activeUser = nil
            eventsSubject.send(AuthSessionEvent(user: nil, isPasswordRecovery: false))
        }

        func deleteAccount() async throws {
            guard let user = activeUser else { throw URLError(.userAuthenticationRequired) }
            records = records.filter { $0.value.userId != user.id }
            activeUser = nil
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
            if shouldSimulateRateLimit || resetRequestCount >= 2 {
                throw NSError(
                    domain: "AuthKit",
                    code: 429,
                    userInfo: [NSLocalizedDescriptionKey: "Rate limit exceeded: Please wait before requesting another reset email"]
                )
            }
            resetRequestCount += 1
        }

        func updatePassword(_ password: String) async throws {}
        func signIn(provider: AuthProvider, redirectTo: URL) async throws -> AuthUser {
            let user = AuthUser(id: UUID(), email: "oauth-\(provider.rawValue)@example.com")
            activeUser = user
            eventsSubject.send(AuthSessionEvent(user: user, isPasswordRecovery: false))
            return user
        }
        func handleCallback(_ url: URL) async throws -> AuthUser {
            let user = AuthUser(id: UUID(), email: "callback@example.com")
            activeUser = user
            eventsSubject.send(AuthSessionEvent(user: user, isPasswordRecovery: false))
            return user
        }

        // RLS Data Access Operations:
        // Policy: USING (auth.uid() = user_id)
        func fetchUserRecords() throws -> [ProtectedUserRecord] {
            guard let currentUserId = activeUser?.id else {
                throw RLSAuthorisationError.unauthenticated
            }
            return records.values.filter { $0.userId == currentUserId }
        }

        // Policy: WITH CHECK (auth.uid() = user_id)
        func insertUserRecord(id: String, content: String) throws {
            guard let currentUserId = activeUser?.id else {
                throw RLSAuthorisationError.unauthenticated
            }
            records[id] = ProtectedUserRecord(id: id, userId: currentUserId, content: content)
        }

        func updateUserRecord(id: String, newContent: String) throws {
            guard let currentUserId = activeUser?.id else {
                throw RLSAuthorisationError.unauthenticated
            }
            guard let existing = records[id], existing.userId == currentUserId else {
                throw RLSAuthorisationError.permissionDenied
            }
            records[id] = ProtectedUserRecord(id: id, userId: currentUserId, content: newContent)
        }

        func deleteUserRecord(id: String) throws {
            guard let currentUserId = activeUser?.id else {
                throw RLSAuthorisationError.unauthenticated
            }
            guard let existing = records[id], existing.userId == currentUserId else {
                throw RLSAuthorisationError.permissionDenied
            }
            records.removeValue(forKey: id)
        }
    }

    // MARK: - Test Cases

    func testEnvironmentConfigurationSeparation() throws {
        let callback = try XCTUnwrap(URL(string: "mytv-auth://auth/callback"))

        let prodConfig = AppAuthConfiguration(
            projectURL: URL(string: "https://ulszjssbmmfnheemfwiy.supabase.co")!,
            publishableKey: "sb_publishable_prod",
            callbackURL: callback,
            storageKey: "com.anuragchourasia.myTV.supabase.session",
            providers: [.google, .github],
            environment: .production
        )

        let stagingConfig = AppAuthConfiguration(
            projectURL: URL(string: "https://staging-ref.supabase.co")!,
            publishableKey: "sb_publishable_staging",
            callbackURL: callback,
            storageKey: "com.anuragchourasia.myTV.supabase.staging.session",
            providers: [.google, .github],
            environment: .staging
        )

        XCTAssertEqual(prodConfig.environment, .production)
        XCTAssertEqual(stagingConfig.environment, .staging)
        XCTAssertNotEqual(prodConfig.projectURL, stagingConfig.projectURL)
        XCTAssertNotEqual(prodConfig.storageKey, stagingConfig.storageKey, "Staging and prod must use isolated session storage keys")

        // Validate bundle default environment
        let bundleConfig = try XCTUnwrap(AppAuthConfiguration.fromBundle())
        XCTAssertEqual(bundleConfig.environment, .production)
        XCTAssertTrue(bundleConfig.storageKey.hasSuffix(".supabase.session"))

        let stagingBundleConfig = try XCTUnwrap(AppAuthConfiguration.fromBundle(environment: .staging))
        XCTAssertEqual(stagingBundleConfig.environment, .staging)
        XCTAssertTrue(stagingBundleConfig.storageKey.hasSuffix(".supabase.staging.session"))
    }

    func testCrossUserAuthorizationAndRowLevelSecurity() throws {
        let backend = MockRLSDatabaseBackend()
        let userA = AuthUser(id: UUID(), email: "usera@mytv.test")
        let userB = AuthUser(id: UUID(), email: "userb@mytv.test")

        // 1. User A creates protected records
        backend.setCurrentUser(userA)
        try backend.insertUserRecord(id: "record-1", content: "User A Sensitive Watch History")
        try backend.insertUserRecord(id: "record-2", content: "User A Cloud Preferences")

        let userARecords = try backend.fetchUserRecords()
        XCTAssertEqual(userARecords.count, 2)
        XCTAssertEqual(userARecords.map(\.id).sorted(), ["record-1", "record-2"])

        // 2. User B logs in (User A logs out)
        backend.setCurrentUser(userB)

        // RLS Read isolation: User B's query returns only User B's records (empty)
        let userBRecords = try backend.fetchUserRecords()
        XCTAssertTrue(userBRecords.isEmpty, "User B must not see User A's records under RLS")

        // RLS Mutation isolation: User B attempts to update User A's record
        XCTAssertThrowsError(try backend.updateUserRecord(id: "record-1", newContent: "Hacked Content")) { error in
            guard let rlsError = error as? RLSAuthorisationError else {
                XCTFail("Expected RLSAuthorisationError, got \(error)")
                return
            }
            XCTAssertEqual(rlsError, .permissionDenied)
        }

        // RLS Deletion isolation: User B attempts to delete User A's record
        XCTAssertThrowsError(try backend.deleteUserRecord(id: "record-1")) { error in
            guard let rlsError = error as? RLSAuthorisationError else {
                XCTFail("Expected RLSAuthorisationError, got \(error)")
                return
            }
            XCTAssertEqual(rlsError, .permissionDenied)
        }

        // 3. Unauthenticated access isolation
        backend.setCurrentUser(nil)
        XCTAssertThrowsError(try backend.fetchUserRecords()) { error in
            XCTAssertEqual(error as? RLSAuthorisationError, .unauthenticated)
        }
        XCTAssertThrowsError(try backend.insertUserRecord(id: "unauth", content: "Forbidden")) { error in
            XCTAssertEqual(error as? RLSAuthorisationError, .unauthenticated)
        }

        // 4. User A returns and mutates their own record
        backend.setCurrentUser(userA)
        try backend.updateUserRecord(id: "record-1", newContent: "User A Updated History")
        XCTAssertEqual(backend.records["record-1"]?.content, "User A Updated History")

        try backend.deleteUserRecord(id: "record-1")
        XCTAssertNil(backend.records["record-1"])
        XCTAssertEqual(try backend.fetchUserRecords().count, 1)
    }

    func testSessionRevocationAndTokenInvalidation() async throws {
        let backend = MockRLSDatabaseBackend()
        let authService = AuthService(backend: backend)
        let session = SessionManager(authService: authService)

        // 1. Sign in active session
        await session.signIn(email: "valid@mytv.test", password: "Password123!")
        guard case .authenticated = session.state else {
            XCTFail("Expected .authenticated state")
            return
        }

        // Refresh succeeds while session is valid
        try await authService.refreshSession()

        // 2. Revoke session via signOut
        await session.signOut()
        XCTAssertEqual(session.state, .unauthenticated)

        let currentUser = try await authService.currentUser()
        XCTAssertNil(currentUser)

        // 3. Verification: subsequent refreshSession must fail
        do {
            try await authService.refreshSession()
            XCTFail("refreshSession must throw when session is revoked")
        } catch {
            // Expected
        }
    }

    func testAbuseControlsAndRateLimitingGracefulHandling() async throws {
        let backend = MockRLSDatabaseBackend()
        let authService = AuthService(backend: backend)
        let session = SessionManager(authService: authService)
        await session.restoreSession()
        XCTAssertEqual(session.state, .unauthenticated)
        let redirectURL = try XCTUnwrap(URL(string: "mytv-auth://auth/callback"))

        // Request 1: succeeds
        await session.requestPasswordReset(email: "victim@mytv.test", redirectTo: redirectURL)
        XCTAssertEqual(session.notice, AuthNotice.passwordResetSent.localizationKey)
        XCTAssertNil(session.errorMessage)

        // Request 2: succeeds
        await session.requestPasswordReset(email: "victim@mytv.test", redirectTo: redirectURL)
        XCTAssertNil(session.errorMessage)

        // Request 3: burst rate-limit trigger (HTTP 429 over_email_send_rate_limit)
        await session.requestPasswordReset(email: "victim@mytv.test", redirectTo: redirectURL)
        XCTAssertNotNil(session.errorMessage)
        XCTAssertEqual(session.semanticError, .generic)
        XCTAssertFalse(session.isLoading)
        XCTAssertEqual(session.state, .unauthenticated)
    }
}
