# MyTV Privacy Inventory & Manifest Declarations

Last updated: 3 November 2026

## 1. Overview & Data Philosophy
MyTV is a live TV and IPTV stream player designed with a strict privacy-first architecture:

- **Zero Tracking**: MyTV does not track users across third-party websites or applications (`NSPrivacyTracking: false`).
- **No Third-Party Ad Networks or Data Brokers**: No advertising identifiers (IDFA), trackers, or commercial telemetry SDKs are included.
- **Offline & Local by Default**: Channel favorites and playback preferences are stored strictly on-device in `UserDefaults`. Stream playlist URLs (`.m3u8`) are network-only and dynamic tokens are never persisted to disk.

---

## 2. Collected Data Categories (Apple Privacy Nutrition Label)

| Data Type | Purpose | Linked to User? | Used for Tracking? | Retention / Storage |
| :--- | :--- | :--- | :--- | :--- |
| **User ID** (`NSPrivacyCollectedDataTypeUserID`) | App Functionality (Cloud account identification when AuthKit is enabled) | Yes | No | Retained in Keychain until sign-out or account deletion. |
| **Email Address** (`NSPrivacyCollectedDataTypeEmailAddress`) | App Functionality (User login, verification, and password recovery) | Yes | No | Retained in Supabase Auth until account deletion. |
| **Other User Content** (`NSPrivacyCollectedDataTypeOtherUserContent`) | App Functionality (User favorite channels) | Yes | No | Stored locally on-device in `UserDefaults` (`favoriteChannelIDs`). |

---

## 3. Required-Reason APIs (`PrivacyInfo.xcprivacy`)

In accordance with Apple App Store review guidelines, MyTV declares all required-reason APIs accessed by the application:

### `NSPrivacyAccessedAPICategoryUserDefaults`
- **Reason Code**: `CA92.1`
- **Declared Usage**: Accessing `UserDefaults` and `@AppStorage` solely to read and write application preferences, user interface layouts (list/grid), favorite channel identifiers (`favoriteChannelIDs`), and developer feature flags on device.

### `NSPrivacyAccessedAPICategoryFileTimestamp`
- **Reason Code**: `C617.1`
- **Declared Usage**: Accessing file attributes and sizes inside the application's local caches directory (`ChannelDiskCache`) to calculate and display cache utilization and provide cache purge functionality.

---

## 4. Network Endpoints & Third-Party SDKs

1. **IPTV Directory & Stream Providers** (`iptv-org` & stream origins):
   - Public read-only stream metadata and m3u8 playlists.
   - Unauthenticated GET requests with standard user agent; no user identity or PII transmitted.
2. **Supabase Auth** (`AuthKit`):
   - Client authentication with public publishable keys over TLS 1.3.

---

## 5. Storage & Sensitive Credential Logging Policy

- **Keychain**: Supabase session tokens are stored in Keychain when authenticated.
- **Cache**: Ephemeral channel JSON cache stored in `.cachesDirectory` and purgeable at any time.
- **Logging Audit**: Logging audit verified that passwords, tokens, channel stream tokens, and user credentials are never logged to console or standard output.

---

## 6. Support & Privacy Contact
- **Privacy Policy**: [https://github.com/Anurag-Chourasia/myTV/blob/main/Docs/PrivacyInventory.md](https://github.com/Anurag-Chourasia/myTV/blob/main/Docs/PrivacyInventory.md)
- **Developer Support**: [mailto:anuragchourasiaios@gmail.com](mailto:anuragchourasiaios@gmail.com)
