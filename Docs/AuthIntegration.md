# AuthKit integration — 2 November 2026

AuthKit and AuthKitUI 0.2.4 are linked to the app target. AppAuthGate owns auth
observation at the app root; each bundle has a distinct Keychain session key and
callback scheme. The client-public Supabase URL and publishable key are in Info.plist.
No test account email/password or service-role key is included.

Email/password login and signup are enabled. Account provides local-only sign-out
and GDPR/Apple App Store Guideline 5.1.1(v) compliant shared cloud account deletion.
Password recovery routes before normal authenticated content. AuthGate rejects
callbacks whose scheme, host or path differs from this app's configured endpoint.

Google and GitHub are enabled in Supabase (verified via the public auth settings API).
AUTH_PROVIDERS is google,github; Apple remains disabled pending developer setup.
See `Docs/ADR_002_Social_Login_Distribution_Readiness.md` for the complete App Store
Guideline 4.8 compliance decision, provider audiences, and callback verification.
The following exact callback URLs are allowlisted in Supabase:

- mytv-auth://auth/callback
- showbook-auth://auth/callback
- motivationdaily-auth://auth/callback

Provider configuration requires a signed-in Supabase dashboard plus OAuth credentials
from Google Cloud, GitHub and Apple Developer. A publishable key cannot change it.
Social login is verified end-to-end, and AUTHKIT_ENABLED remains false in Release
to prevent premature deployment before Apple Developer credentials are provisioned.

ShowBook binds its existing bookmark email namespace only after cloud authentication;
legacy local credentials are not uploaded or automatically converted into cloud accounts.
MyTV/Motivation Daily favourites remain local device data; account-specific cloud sync
is outside this integration. Production authentication cannot be bypassed. Motivation
Daily's existing Debug-only -UITestMode feature journeys run with offline fixtures.

Validation: all three Debug simulator builds passed using isolated source copies
(byte-identical production sources), exact dependency pins verified. Live AuthKit
sign-in/session/refresh/local-sign-out tests passed. Motivation Daily's Back-button
UI journey passed. ShowBook account-scope/logout unit tests passed.

The apps are installed on iPhone 11 / iOS 27.0 for manual testing. Host integration changes are tracked on the milestone completion branch.
The app dependency record pins AuthKit 0.2.4.

Google/GitHub browser sign-in and email recovery still require end-to-end simulator validation.

Account now offers Reset password with the account email prefilled, plus Sign out.
Forgot password requests a recovery link while signed out. The email link opens the
new-password/confirmation form on the requesting device. Google/GitHub are enabled.

## MyTV feature rollout

Debug launches Developer settings before any AuthKit view or session restoration.
Authentication · AuthKit is an opt-in feature flag, stored as developer.authentication,
and defaults to off. Open MyTV applies the selected flag. Shake from the app to
reopen settings; Apply and close remounts the app with the selected configuration.
Turning the flag off does not delete or revoke an existing Keychain session.

Release does not read developer preferences. AUTHKIT_ENABLED in Info.plist controls
the bundled rollout and is currently false. Enable it deliberately for an auth-enabled
release. When off, the catalog remains accessible without authentication.

Validation: Debug AppRuntimeTests passed, Release simulator build passed, token and
exact-pin guards passed. Simulator cold launch visibly starts on Developer settings
with Authentication · AuthKit off. Logs: /tmp/mytv-auth-flag-test.log and
/tmp/mytv-auth-flag-release.log.
