# ADR 002: Social Login Distribution Readiness & Guideline 4.8 Compliance

**Date**: 2 November 2026  
**Status**: Accepted  
**Scope**: `AuthKit`, `myTV`, `ShowBook`, `Motivation Daily`  
**Milestone**: M4 Identity and Privacy (Ticket IOS-18)  
**App Store Review Guideline Reference**: Guideline 4.8 ("Sign in with Apple") & Guideline 5.1.1(v)

---

## 1. Context & Problem Statement

Each application in the portfolio integrates `AuthKit` to support user accounts and data synchronization. The authentication layer supports:
- Email and password sign-in and sign-up (native, pseudonymous).
- OAuth social logins via Supabase Auth (Google, GitHub, and Apple).

Under **Apple App Store Review Guideline 4.8**:
> *"Apps that use a third-party or social login service (such as Google Sign-In, GitHub, Facebook Login, etc.) to set up or authenticate the user’s primary account with the app must also offer Sign in with Apple as an equivalent option."*
>
> *"Sign in with Apple is not required if: Your app exclusively uses your company’s own account setup and sign-in systems."*

If an app submits to the App Store offering third-party social logins (Google and GitHub) without offering Sign in with Apple, Apple Review will issue an immediate rejection under Guideline 4.8.

We must decide the social provider distribution policy, verify provider audiences, validate exact callback endpoints, and record end-to-end evidence before enabling production rollout.

---

## 2. Decision

### 2.1 Provider Ship Strategy

1. **Email / Password (Primary Universal Option)**:
   - Always enabled across all environments.
   - Provides private, tracker-free account creation and authentication.
   - When an app exclusively uses email/password, it is completely exempt from Guideline 4.8.

2. **Social Providers (Google & GitHub)**:
   - Configured and active on the Supabase backend.
   - Audience parameters:
     - **Google Client ID**: `650155383716-76su6imris4fvof7l64stbf2hqdjtk45.apps.googleusercontent.com`
     - **Google Scopes**: `email profile`
     - **GitHub Client ID**: `Ov23liMgSdEkwAz2V39v`
     - **GitHub Scopes**: `user:email`
     - **Supabase Gateway Redirect URI**: `https://ulszjssbmmfnheemfwiy.supabase.co/auth/v1/callback`

3. **Equivalent Privacy-Preserving Login Option (Sign in with Apple)**:
   - `AuthKit` implements full architectural and UI support for `AuthProvider.apple`:
     - System `.apple.logo` and standard "Continue with Apple" label.
     - Dynamic contrast adhering to Apple Human Interface Guidelines (white on black in light mode, black on white in dark mode).
     - Routed via `SupabaseAuthBackend.signIn(provider: .apple, redirectTo:)`.
   - Current Backend State: Apple is **disabled** on Supabase (`"apple": false`) pending Apple Developer Team ID, Services ID, Key ID, and private key (`.p8`) enrollment.
   - Attempting Apple OAuth against the live backend returns HTTP 400 (`Unsupported provider: provider is not enabled`), which `SessionManager` catches gracefully into `errorMessage`.

4. **Production Release Gating Policy**:
   - Because Apple OAuth is currently inactive on the backend, shipping social logins (Google/GitHub) in a live App Store build would trigger rejection under Guideline 4.8.
   - **`AUTHKIT_ENABLED` remains `<false/>` in all production `Info.plist` files** until backend developer credentials and release gates are completed.
   - If an auth-enabled release is cut before Apple Developer private keys are provisioned in Supabase, `AUTH_PROVIDERS` will be set to empty/disabled, shipping email/password exclusively (which is 100% Guideline 4.8 compliant).
   - Once Apple Developer credentials are provisioned in Supabase, `AUTH_PROVIDERS` will ship with `apple,google,github`.

---

## 3. Provider Audiences & Callbacks Verification Audit

### 3.1 Live Backend Endpoint Responses

Real HTTP responses recorded from the Supabase production gateway (`https://ulszjssbmmfnheemfwiy.supabase.co`):

| Endpoint | Method / Query | HTTP Response | Evidence / Redirect Location |
|---|---|---|---|
| `/auth/v1/settings` | `GET` | `200 OK` | `{"external": {"google": true, "github": true, "apple": false, "email": true}}` |
| `/auth/v1/authorize` | `provider=google` | `302 Found` | `https://accounts.google.com/o/oauth2/v2/auth?client_id=650155383716-76su6imris4fvof7l64stbf2hqdjtk45...` |
| `/auth/v1/authorize` | `provider=github` | `302 Found` | `https://github.com/login/oauth/authorize?client_id=Ov23liMgSdEkwAz2V39v...` |
| `/auth/v1/authorize` | `provider=apple` | `400 Bad Request` | `{"code":400,"error_code":"validation_failed","msg":"Unsupported provider: provider is not enabled"}` |
| `/auth/v1/authorize` | `redirect_to=unauthorized` | Evaluated against allowlist | Unallowlisted redirects are rejected by GoTrue validation |

### 3.2 Allowlisted Client Callback URLs

The following exact deep-link callback URLs are registered in Supabase and matched in client app configurations:

1. **myTV**:
   - Scheme: `mytv-auth`
   - Callback URL: `mytv-auth://auth/callback`
   - Bundle Identifier: `com.anuragchourasia.myTV`
2. **ShowBook**:
   - Scheme: `showbook-auth`
   - Callback URL: `showbook-auth://auth/callback`
   - Bundle Identifier: `com.anuragchourasia.ShowBook`
3. **Motivation Daily**:
   - Scheme: `motivationdaily-auth`
   - Callback URL: `motivationdaily-auth://auth/callback`
   - Bundle Identifier: `com.anuragchourasia.MotivationDaily`

### 3.3 Security & Spoofing Guardrails

`AppAuthConfiguration.accepts(_ url: URL)` enforces:
```swift
url.scheme?.lowercased() == callbackURL.scheme?.lowercased()
&& url.host?.lowercased() == callbackURL.host?.lowercased()
&& url.path == callbackURL.path
```
- Rejects alternate schemes (`other-app://auth/callback`).
- Rejects domain spoofing (`mytv-auth://attacker.com/callback`).
- Rejects invalid path targeting (`mytv-auth://auth/malicious`).

---

## 4. Automated Test Verification

Automated coverage in `AuthenticationLifecycleTests`:
- `testSocialLoginDistributionReadinessAndProviderAudiences()` validates bundle configuration, scheme registration, callback URL allowlist compliance, and multi-provider state handling.
- `testDisabledProviderGracefulDegradation()` verifies that attempting an unconfigured provider (e.g. Apple) catches the backend error, exposes a recoverable message to the user, and keeps the session unauthenticated without crash or corrupt state.
