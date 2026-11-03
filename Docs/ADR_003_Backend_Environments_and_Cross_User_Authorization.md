# ADR 003: Backend Environment Separation, Row-Level Security, and Disaster Recovery

**Date**: 3 November 2026  
**Status**: Accepted  
**Scope**: `AuthKit`, `myTV`, `ShowBook`, `Motivation Daily`  
**Milestone**: M4 Identity and Privacy (Ticket IOS-19)

---

## 1. Context & Objectives

As cloud authentication and data synchronization are integrated across the iOS portfolio, we must enforce rigorous backend security boundaries:
1. **Environment Isolation**: Prevent development/staging testing from corrupting or colliding with production user credentials, sessions, and databases.
2. **Cross-User Authorization**: Ensure that User A cannot read, mutate, or delete User B's protected records under PostgreSQL Row-Level Security (RLS).
3. **Session Revocation**: Guarantee that token revocation and local sign-out immediately terminate data access and prevent token reuse.
4. **Abuse Controls**: Gracefully absorb email throttling and rate-limiting without crashing or corrupting client state.
5. **Operational Rehearsal**: Formalize actionable runbooks for credential rotation and disaster recovery (PITR backup restore).

---

## 2. Environment Architecture & Configuration Separation

### 2.1 Multi-Environment Abstraction

`AuthKit` (`0.2.5+`) defines `AuthEnvironment`:
- `.production`: Production Supabase tenant (`https://ulszjssbmmfnheemfwiy.supabase.co`).
- `.staging`: Staging Supabase tenant / isolated developer environment.

### 2.2 Keychain Storage Key Isolation

To eliminate token collisions on device when running staging builds or switching profiles:
- **Production Session Storage Key**: `<bundleID>.supabase.session`
- **Staging Session Storage Key**: `<bundleID>.supabase.staging.session`

`AppAuthConfiguration.fromBundle(_:environment:)` resolves:
1. `SUPABASE_STAGING_URL` / `SUPABASE_STAGING_PUBLISHABLE_KEY` when `environment == .staging`.
2. Falls back cleanly to base bundle keys if explicit staging keys are not configured.
3. Automatically appends the appropriate storage key suffix, ensuring strict physical Keychain isolation.

### 2.3 Runtime Policy Enforcement

- In `Release` builds, `AppRuntime.authEnvironment` strictly evaluates to `.production`. Developer preferences are ignored.
- In `Debug` builds, developer settings can toggle between `.production` and `.staging` for manual end-to-end testing.

---

## 3. PostgreSQL Row-Level Security (RLS) Policies

All user-owned tables across the portfolio backend must have Row-Level Security enabled. The database enforces authorization at the database engine level, independent of API clients.

### 3.1 Standard RLS Policy Template

```sql
-- Enable Row Level Security on user-specific tables
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_bookmarks ENABLE ROW LEVEL SECURITY;

-- 1. SELECT: Users can only query their own rows
CREATE POLICY "Users can only read own records"
ON public.user_favorites
FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

-- 2. INSERT: Users can only create rows where user_id matches their authenticated UID
CREATE POLICY "Users can only insert own records"
ON public.user_favorites
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

-- 3. UPDATE: Users can only modify their own existing rows
CREATE POLICY "Users can only update own records"
ON public.user_favorites
FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- 4. DELETE: Users can only delete their own rows
CREATE POLICY "Users can only delete own records"
ON public.user_favorites
FOR DELETE
TO authenticated
USING (auth.uid() = user_id);
```

### 3.2 Authorization Guardrails Tested

Automated test suite [`myTVTests/BackendAuthorizationAndRLSTests.swift`](file:///Users/anuragchourasia/Desktop/Projects/MyTV/myTVTests/BackendAuthorizationAndRLSTests.swift) verifies:
- **Read Isolation**: Querying records while authenticated as User B returns an empty set for records created by User A.
- **Mutation Isolation**: Direct update attempts by User B targeting User A's `record_id` throw `permissionDenied`.
- **Deletion Isolation**: Direct delete attempts by User B targeting User A's `record_id` throw `permissionDenied`.
- **Unauthenticated Rejection**: Requests without a valid JWT are blocked unconditionally with `unauthenticated`.

---

## 4. Session Revocation & Abuse Controls

### 4.1 Token Invalidation Lifecycle

1. When a user taps **Sign Out**:
   - `SessionManager.signOut()` clears in-memory `state` to `.unauthenticated`.
   - `SupabaseAuthBackend.signOut(scope: .local)` purges tokens from Keychain storage.
2. When backend revocation occurs (e.g. password change on another device or admin revocation):
   - In-flight refresh token exchange fails.
   - `refreshSession()` throws `userAuthenticationRequired`.
   - The app transitions to `.unauthenticated` without deadlocks or unhandled exceptions.

### 4.2 Throttling & Abuse Handling

- Supabase Auth enforces email rate limits (e.g., maximum 1 email per 60 seconds per recipient).
- Burst calls to `requestPasswordReset` trigger HTTP 429 (`over_email_send_rate_limit`).
- `SessionManager` captures the 429 error into `errorMessage` for user-friendly presentation ("Rate limit exceeded: Please wait before requesting another reset email"), keeping the UI responsive and preventing retry loops.

---

## 5. Operational Runbooks

### 5.1 Runbook 1: Publishable Key Rotation (`SUPABASE_PUBLISHABLE_KEY`)

When rotating client credentials (e.g. periodic security hygiene or key exposure):

1. **Backend Generation**: In the Supabase Dashboard (`Project Settings` > `API`), create a new API key pair.
2. **Transition Window**: Supabase supports overlapping valid JWT signatures.
3. **Client Staged Rollout**:
   - Update `SUPABASE_PUBLISHABLE_KEY` in `myTV/Info.plist`, `ShowBook/Info.plist`, and `Motivation Daily/Info.plist`.
   - Update `Scripts/dependencies.json` and publish an app update.
4. **Deprecation**: Monitor telemetry; once legacy client traffic drops below threshold, revoke the deprecated key in the dashboard.

### 5.2 Runbook 2: Point-in-Time Recovery (PITR) & Disaster Recovery

In the event of accidental data corruption or schema incident:

1. **Initiate Restore**:
   - Open Supabase Dashboard > `Database` > `Backups` > `Point in Time`.
   - Select the target timestamp immediately prior to the incident (e.g., `YYYY-MM-DDTHH:MM:SSZ`).
2. **Staging Verification**:
   - Restore first into a staging branch/instance.
   - Run verification queries checking foreign keys, profile counts, and bookmark integrity.
3. **Production Cutover**:
   - Execute failover to the restored database instance.
4. **Client Recovery**:
   - Clients with stale sessions automatically refresh. If an account was created after the restore point, token refresh fails and the client cleanly returns to `.unauthenticated`, allowing standard sign-up or recovery.
