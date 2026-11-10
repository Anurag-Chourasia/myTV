# Architecture Governance Audit Report — `myTV`

> **Audit Basis**: [`AGENTS.md`](./AGENTS.md) / [`GEMINI.md`](./GEMINI.md) (*Ecosystem Architectural Governance Specification — Standard for All Swift Packages (SPMs) and Host Applications*)
> **Target Repository**: `myTV`
> **Audit Scope**: Full production codebase (`myTV/`), test harness (`TestSupport/`), dependency configuration (`Scripts/dependencies.json`, `myTV.xcodeproj`), and CI/linting rules (`.swiftlint.yml`, `.swiftlint-baseline.json`, `Scripts/`).

---

## 1. Executive Summary & Compliance Scorecard

| Governance Pillar | Spec Ref | Status | Violations | Key Findings |
| :--- | :--- | :---: | :---: | :--- |
| **Clean Architecture Layer Isolation** | §1, §4.1 | ❌ **Failing** | **12** | Unsanctioned `Core/` & `Developer/` layers; Views/ViewModels instantiate concrete `Data` types (`ChannelDiskCache`, `FavoriteChannelStore`) and depend on concrete UseCase (`DefaultFetchStreamsForChannelUseCase`); `AppDI.shared` service-locator calls in Presentation; `UIKit` imported in ViewModels. |
| **KeyPath Localization (`LocalisationKit`)** | §2, §3.1, §4.2 | ❌ **Failing** | **18+** | 30 hardcoded English category strings in `CategoryDisplay.swift`; hardcoded strings in `DeveloperSettingsView.swift` & `ChannelDiskCache.swift`; raw string key lookups (`"app.retry"`, `"app.ok"`); `Text(String(\...))` instead of `Text(\.keyPath)`. |
| **KeyPath Design Tokens (`DesignTokensKit`)** | §2, §3.2, §4.2 | ⚠️ **Partial** | **15** | Views use discouraged verbose namespaces (`Typography.headline`, `ColorTheme.default.red`, `DesignMetricTheme.default.p40`, `ScaleToken.p1_15`, `LayoutPreset.compactMedia`) instead of KeyPath modifiers (`.font(\.headline)`). |
| **Zero Ad-Hoc Networking (`CommonNetworkingKit`)** | §3.5, §4.2 | ❌ **Failing** | **3** | `ImageLoader.swift`, `CachedAsyncImage.swift`, and `AppDI.swift` use `URLSession.shared` directly outside `CommonNetworkingKit` and the `Data` layer. |
| **Auth Boundary (`AuthKit`)** | §3.3, §4.2 | ⚠️ **Partial** | **2** | `DeveloperSettingsView.swift` imports `AuthKitSupabase` and calls `SupabaseBackendFactory.make` outside `AppDI`; `supabase-swift` is pinned directly in host `Scripts/dependencies.json`. |
| **SPM Boundaries (`FoundationKit`, `AppStubData`, `DeveloperProfileKit`, `UIComponentsKit`)** | §3.4–§3.8 | ❌ **Failing** | **9** | Raw `print()` instead of `FoundationKit` logger; in-house `DeveloperStubRepository` instead of `AppStubData`; in-house `DeveloperSettingsView` instead of `DeveloperProfileKit`; missing `#Preview`s on 14/15 Views. |
| **CI/CD & SwiftLint Zero Tolerance** | §5.1, §5.3 | ❌ **Failing** | **4** | `.swiftlint-baseline.json` masks **52 existing lint errors**; active force unwraps (`!`) in `DeveloperSettingsView.swift`; custom SwiftLint rules only scan `.*/Presentation/.*`. |

---

## 2. Detailed Violations by Governance Rule

### 2.1. Clean Architecture Layer Isolation & Dependency Hierarchy (§1 & §4.1)

#### ❌ Violation 1: Unsanctioned Top-Level `Core/` and `Developer/` Layers Breaking the 4-Layer Contract
* **Governance Rule (§4.1)**: Host apps must strictly isolate into four layers: `Domain/`, `Data/`, `Presentation/`, and `App/`.
* **What breaks it**:
  * `myTV/Core/` mixes **Presentation UI** (`CachedAsyncImage.swift`, `ImageLoader.swift`), **UIKit Hardware Adapters** (`HapticServiceImpl.swift`), **Presentation Formatters** (`CategoryDisplay.swift`, `CountryDisplay.swift`), and **Network Reachability** (`ReachabilityServiceImpl.swift`).
  * `myTV/Developer/` mixes **App Launch Composition** (`TVLaunchView`), **Data Layer Repository Implementations** (`DeveloperStubRepository`), and **Presentation Views** (`DeveloperSettingsView`).

#### ❌ Violation 2: Presentation & View Layer Directly Instantiating Concrete `Data` Layer Types
* **Governance Rule (§4.1.3 & §4.1.4)**: *"Presentation Layer — Strictly Banned: Direct calls to `Data` layer... The `App` layer is the **only** place allowed to assemble concrete dependencies."*
* **What breaks it**:
  1. `myTV/Developer/DeveloperSettingsView.swift:169`:
     ```swift
     private let diskCache = ChannelDiskCache()
     ```
     A SwiftUI `View` directly instantiates concrete `Data` layer `ChannelDiskCache` and calls `diskCache.clear()`, `diskCache.entryCount`, and `diskCache.formattedFileSize` (lines 226, 320–324).
  2. `myTV/Presentation/Screens/ChannelList/ChannelListViewModel.swift:166-167`:
     ```swift
     self.favorites = favorites ?? FavoriteChannelStore()
     self.imageCache = imageCache ?? DefaultImageCache.shared
     ```
     `ChannelListViewModel` (in `Presentation`) directly instantiates the `Data` layer's `FavoriteChannelStore` and accesses `DefaultImageCache.shared`.

#### ❌ Violation 3: ViewModel Depending on Concrete UseCase Class Instead of Domain Protocol
* **Governance Rule (§1 & §4.1.3)**: `Presentation --> Domain` (Protocols/Interfaces).
* **What breaks it**:
  * `myTV/Presentation/Screens/StreamList/StreamListViewModel.swift:52-57`:
    ```swift
    init(
        fetchStreams: DefaultFetchStreamsForChannelUseCase, // Concrete class instead of FetchStreamsForChannelUseCase protocol
        reachability: ReachabilityService,
        haptics: HapticService,
        notificationCenter: NotificationCenter = .default
    )
    ```
    While the stored property on line 34 is typed as `FetchStreamsForChannelUseCase`, the initializer requires the concrete class `DefaultFetchStreamsForChannelUseCase`, preventing protocol-based UseCase mocking in unit tests.

#### ❌ Violation 4: Service Locator Anti-Pattern (`AppDI.shared`) Inside Presentation Views
* **Governance Rule (§4.1.4)**: *"App Layer (Composition Root): Wires concrete implementations to Domain interfaces and injects them into ViewModels. The **only** place allowed to assemble concrete dependencies."*
* **What breaks it**: Presentation views reach out to the global singleton `AppDI.shared` instead of receiving dependencies from the composition root:
  * `myTV/Presentation/Screens/ChannelList/ChannelListView.swift:22-27`: Calls `AppDI.shared.makeStreamListViewModel()` and `AppDI.shared.makeAboutViewModel()`.
  * `myTV/Presentation/Controls/MultiSelectView.swift:26`: Calls `AppDI.shared.getHaptics()`.
  * `myTV/Presentation/Controls/ScreenTools.swift:14-15, 55-56`: Calls `AppDI.shared.getHaptics()` and `AppDI.shared.makeAboutViewModel()`.
  * `myTV/Developer/DeveloperSettingsView.swift:57-60, 280`: Calls `AppDI.shared.makeChannelListViewModel(...)` and `AppDI.shared.getHaptics().selection()`.

#### ❌ Violation 5: `UIKit` Imported in ViewModels & Service Protocols
* **Governance Rule (§4.1)**: ViewModels should coordinate Domain UseCases without coupling to `UIKit`.
* **What breaks it**:
  * `myTV/Presentation/Screens/ChannelList/ChannelListViewModel.swift:10`: `import UIKit` (unused).
  * `myTV/Presentation/Screens/StreamList/StreamListViewModel.swift:18-19`: `import AVKit` and `import UIKit` directly in the ViewModel (`UIApplication.didEnterBackgroundNotification`, `AVAudioSession`, `AVPlayer`).
  * `myTV/Core/Haptic/HapticService.swift:9`: `import UIKit` in a pure protocol definition file that uses no `UIKit` types.

#### ❌ Violation 6: `Data` Layer Coupled to Developer `UserDefaults` Keys & Presentation Strings
* **Governance Rule (§4.1.2)**: `Data` layer must only depend on `Domain`, `CommonNetworkingKit`, and `FoundationKit`.
* **What breaks it**:
  * `myTV/Data/Network/Client/HTTPClient.swift:20-21`: Reads `UserDefaults.standard.object(forKey: "developer.httpLogs")` directly inside `CommonNetworkingHTTPClient.init` instead of receiving configuration from `AppDI`.
  * `myTV/Data/Cache/ChannelDiskCache.swift:26-30`: Computes user-facing English string `"0 KB"` / `ByteCountFormatter` inside a `Data` cache class solely for `DeveloperSettingsView`.
* **Domain UseCase CQRS Leak**:
  * `myTV/Domain/UseCases/FetchChannelsUseCase.swift:7-10`: Mixes command (`func clearCache()`) and query (`func execute(forceRefresh: Bool)`) responsibilities on a single `FetchChannelsUseCase`.

---

### 2.2. KeyPath-Driven Localization & Zero Raw Strings Rule (§2, §3.1, §4.2)

#### ❌ Violation 7: Hardcoded User-Facing Raw Strings Bypassing `LocalisationKit`
* **Governance Rule (§3.1 & §4.2)**: *"Zero Raw Strings Rule: No host application or SPM may ever hardcode user-facing string literals. Every string must be registered in `LocalisationKit`."*
* **What breaks it**:
  1. `myTV/Core/Localization/CategoryDisplay.swift:60-91`: Hardcodes **30 English category strings** (`"🎞 Animation"`, `"🚗 Auto"`, `"💼 Business"`, `"🎭 Entertainment"`, `"🔞 Adult"`, etc.) in a static dictionary. None of these localize to `ar`, `fr`, etc.
  2. `myTV/Developer/DeveloperSettingsView.swift:156`:
     ```swift
     var buttonTitle = "Apply and close"
     ```
  3. `myTV/Developer/DeveloperSettingsView.swift:321-325`:
     ```swift
     if count == 0 {
         cacheSummary = "0 channels (0 KB)"
     } else {
         cacheSummary = "\(count) channels (\(diskCache.formattedFileSize))"
     }
     ```
  4. `myTV/Data/Cache/ChannelDiskCache.swift:28`:
     ```swift
     guard bytes > 0 else { return "0 KB" }
     ```
  5. `myTV/Presentation/Controls/MultiSelectViewModel.swift:57`:
     ```swift
     var searchPrompt: String { "\(String(\MyTVStrings.search)) \(title)" }
     ```
     Uses manual string concatenation instead of parameterized localization interpolation (`Text(\.key, arguments: [...])`).

#### ❌ Violation 8: Raw String Key Lookups via `LocalizationController.shared.string(...)`
* **Governance Rule (§2 & §3.1)**: All strings must be accessed via strongly-typed KeyPaths (`\.keyPath`).
* **What breaks it**:
  1. `myTV/Presentation/Components/State/ErrorViewModel.swift:16`:
     ```swift
     retryTitle: LocalizationController.shared.string("app.retry")
     ```
  2. `myTV/Presentation/Screens/StreamList/StreamListViewModel.swift:175`:
     ```swift
     var okButtonTitle: String {
         LocalizationController.shared.string("app.ok")
     }
     ```

#### ❌ Violation 9: `Text(String(\...))` Anti-Pattern Instead of Mandatory `Text(\.keyPath)`
* **Governance Rule (§2 & §3.1)**: Consumer `View`s must use `Text(\.keyPath)` directly rather than converting KeyPaths to `String` first (`Text(String(\MyTVStrings...))`), which also bypasses SwiftUI environment locale reactivity.
* **What breaks it**:
  * `myTV/Presentation/Components/Channel/ChannelGridView.swift:28`: `Text(String(\MyTVStrings.channelStreamsUnavailable))`
  * `myTV/Presentation/Components/Channel/ChannelRowView.swift:28`: `Text(String(\MyTVStrings.channelStreamsUnavailable))`
  * `myTV/Presentation/Components/Channel/FavoriteButton.swift:29`: `.accessibilityHint(Text(String(\MyTVStrings.a11yFavoriteHint)))`
  * `myTV/Presentation/Controls/ChannelStickyBar.swift:32`: `.accessibilityValue(scope == tab ? Text(String(\MyTVStrings.a11ySelected)) : Text(""))`
  * `myTV/Presentation/Controls/MultiSelectView.swift:95`: `.accessibilityValue(viewModel.isSelected(option) ? Text(String(\MyTVStrings.a11ySelected)) : Text(""))`
  * `myTV/Presentation/Screens/AboutView/AboutView.swift:111-112`: `.accessibilityLabel(Text(String(\MyTVStrings.a11yMenuOptions)))` and `.accessibilityHint(Text(String(\MyTVStrings.a11yMenuOptionsHint)))`
  * `myTV/Presentation/Screens/ChannelList/ChannelListView.swift:169, 189, 367-368`: `.accessibilityHint(Text(String(\MyTVStrings.a11yChannelOpenHint)))`, etc.
  * `myTV/Presentation/Screens/StreamList/StreamListView.swift:135`: `.accessibilityHint(Text(String(\MyTVStrings.a11yStreamPlayHint)))`
  * `myTV/Developer/DeveloperSettingsView.swift:234-297`: 9 occurrences of `Text(String(\MyTVStrings...))` and `Text(String(\CommonStrings...))`.

---

### 2.3. KeyPath-Driven Design Tokens (`DesignTokensKit`) (§2, §3.2, §4.2)

#### ⚠️ Violation 10: Verbose Namespaced Token Access Instead of Mandatory KeyPaths
* **Governance Rule (§2 Table)**:
  * `.font(DesignTokens.Typography.titleMedium)` is explicitly listed as **Verbose Namespaced (Discouraged)**; `.font(\.titleMedium)` is the **Mandatory Standard (KeyPath Syntax)**.
  * `.background(BrandPalette.current.surface)` and `.cornerRadius(LayoutPreset.cardRadius)` are listed as **Verbose Namespaced (Discouraged)**; KeyPath syntax (`\.surface`, `\.cardRadius`) is mandatory.
* **What breaks it**:
  1. **Verbose `Typography.*` namespace instead of `.font(\...)`**:
     * `myTV/Presentation/Components/Channel/ChannelGridView.swift:23, 29`: `.font(Typography.headline)`, `.font(Typography.caption)`
     * `myTV/Presentation/Components/Channel/ChannelRowView.swift:23, 29`: `.font(Typography.headline)`, `.font(Typography.caption)`
     * `myTV/Presentation/Components/Channel/ChannelSectionHeader.swift:16`: `.font(Typography.headline)`
     * `myTV/Presentation/Controls/ChannelStickyBar.swift:19`: `.font(Typography.subheadline.weight(.semibold))`
     * `myTV/Presentation/Screens/StreamList/StreamListView.swift:121, 124`: `.font(Typography.headline)`, `.font(Typography.caption)`
     * `myTV/Developer/DeveloperSettingsView.swift:71, 73, 76, 298`: `.font(Typography.caption2)`, `.font(Typography.caption)`
  2. **Verbose `ColorTheme.default.*` / `DesignMetricTheme.default.*` / `ScaleToken.*` / `LayoutPreset.*` static properties**:
     * `myTV/Presentation/Components/Banner/OfflineBanner.swift:11`: `backgroundColor: ColorTheme.default.red` (bypasses environment theme switching).
     * `myTV/Developer/DeveloperSettingsView.swift:312`: `.toggleStyle(SwitchToggleStyle(tint: ColorTheme.default.green))`
     * `myTV/Presentation/Components/Channel/ChannelLogo.swift:13-14`: `DesignMetricTheme.default.p40`
     * `myTV/Presentation/Screens/ChannelList/ChannelListView.swift:199`: `DesignMetricTheme.default.p160 : DesignMetricTheme.default.p110`
     * `myTV/Presentation/Components/Channel/FavoriteButton.swift:28`: `.scaleEffect(isFavorite ? ScaleToken.p1_15 : ScaleToken.p1_0)`
     * `myTV/Presentation/Components/Skeleton/SkeletonListView.swift:11-16`, `myTV/Presentation/Screens/ChannelList/ChannelListView.swift:157-195`, `myTV/Presentation/Screens/StreamList/StreamListView.swift:104-118`: Direct `LayoutPreset.compactMedia.*` references.

---

### 2.4. Zero Ad-Hoc Network Calls (`CommonNetworkingKit`) (§3.5 & §4.2)

#### ❌ Violation 11: Direct `URLSession.shared` Networking Outside `CommonNetworkingKit` and `Data` Layer
* **Governance Rule (§4.2)**: *"Zero Ad-Hoc Network Calls — Prohibited Anti-Pattern: Custom `URLSession.shared.dataTask` | Required Mandate: Route through `CommonNetworkingKit` via Data layer."*
* **What breaks it**:
  1. `myTV/Core/ImageCaching/ImageLoader.swift:25-53`:
     * Injects `session: URLSession = .shared` and performs raw `let (data, response) = try await session.data(from: url)` and manual `(200..<300).contains(http.statusCode)` checks directly inside `Core/ImageCaching`, completely bypassing `CommonNetworkingKit` (retry policies, HTTP logging, status validation) and the `Data` layer.
  2. `myTV/Core/ImageCaching/CachedAsyncImage.swift:17`:
     * Exposes `session: URLSession = .shared` directly in a SwiftUI `View` initializer.
  3. `myTV/App/AppDI.swift:18, 66-68`:
     * Declares `private lazy var urlSession: URLSession = .shared` and `func getURLSession() -> URLSession`.

---

### 2.5. `AuthKit` Boundary & Dependency Rules (§1, §3.3, §4.1.4)

#### ⚠️ Violation 12: `AuthKitSupabase` Wired Outside the Composition Root (`AppDI`) & Direct `supabase-swift` Host Dependency
* **Governance Rule (§1, §3.3, §4.1.4)**:
  * In the §1 Dependency Graph, only `App` (Composition Root) wires concrete implementations (`Data`, `AuthKitSupabase`). `Presentation` only depends on `AuthKitUI`.
  * §3.3: *"Swapping `AuthKitSupabase` with a mock or other backend provider requires zero code changes in host applications."*
* **What breaks it**:
  1. `myTV/Developer/DeveloperSettingsView.swift:5, 54`:
     `TVLaunchView` (in `Developer/DeveloperSettingsView.swift`) directly imports `AuthKitSupabase` and passes `backendFactory: SupabaseBackendFactory.make` instead of receiving an abstract `AuthBackend` factory from `AppDI`.
  2. `Scripts/dependencies.json:30-33`:
     `supabase-swift` is pinned directly in the host repository's dependency manifest rather than being encapsulated purely as a transitive internal dependency of `AuthKitSupabase`.

---

### 2.6. Ecosystem SPM Responsibilities (`FoundationKit`, `UIComponentsKit`, `AppStubData`, `DeveloperProfileKit`) (§3.4–§3.8)

#### ❌ Violation 13: Raw `print()` Statements & Ad-Hoc Formatters Instead of `FoundationKit`
* **Governance Rule (§3.6)**: `FoundationKit` is the single cross-cutting infrastructure package for unified structured logging (`UnifiedLogger`, `AppLogger`), formatting factories, and feature flag/runtime configuration primitives.
* **What breaks it**:
  * Raw `print()` calls instead of `FoundationKit` structured logging:
    * `myTV/Core/ImageCaching/ImageLoader.swift:60`: `print("❌ Image load failed:", error.localizedDescription)`
    * `myTV/Data/Cache/ChannelDiskCache.swift:38`: `print("❌ Failed to save channel cache:", error)`
    * `myTV/Presentation/Screens/StreamPlayerView/StreamPlayerView.swift:48-58`: 3 raw `print("Failed to activate AVAudioSession...")` calls.
  * Ad-hoc `ByteCountFormatter` in `myTV/Data/Cache/ChannelDiskCache.swift:29`.
  * Ad-hoc feature flag and runtime configuration parsing via `UserDefaults.standard` in `myTV/Developer/AppRuntime.swift:6-69`.

#### ❌ Violation 14: In-House Stub Repository Instead of `AppStubData`
* **Governance Rule (§3.7)**: *"`AppStubData` supplies static, immutable JSON payloads and mock repositories for UI Previews, unit tests, and snapshot tests."*
* **What breaks it**:
  * `myTV/Developer/AppRuntime.swift:72-134` defines an in-house `DeveloperStubRepository` and custom `Catalog` JSON decoder inside the host app target instead of consuming `AppStubData`.

#### ❌ Violation 15: In-House `DeveloperSettingsView` & Unprotected Release Code in `Developer/` Instead of `DeveloperProfileKit`
* **Governance Rule (§3.8)**: *"`DeveloperProfileKit`: Responsibilities: Environment switching (Production, Staging, Local/Mock). Diagnostic logs viewer, network inspector, cache clearers. Strict Invariants: Self-contained UI and logic. Must be stripped or protected behind compiler flags (`#if DEBUG`) in release builds."*
* **What breaks it**:
  1. `myTV/Developer/DeveloperSettingsView.swift:155-328` re-implements environment switching, stub scenario selection, cache clearing, HTTP log toggling, and version simulation inside the host app instead of consuming `DeveloperProfileKit`.
  2. `myTV/Developer/DeveloperSettingsView.swift:1-66`: `TVAuthLocalizer`, `extension LocalizationController: @retroactive AuthLocalizing`, and `TVLaunchView` are placed inside `Developer/DeveloperSettingsView.swift` **outside** `#if DEBUG`, shipping in Release builds from the `Developer/` folder.

#### ⚠️ Violation 16: Missing SwiftUI `#Preview`s & In-House Reusable UI Components (`UIComponentsKit`)
* **Governance Rule (§3.4 & §4.2)**: *"Zero In-House Duplicate UI... Every component must supply SwiftUI Previews (Light, Dark, and Dynamic Type modes)."*
* **What breaks it**:
  * Generic reusable components such as `MultiSelectView`, `SkeletonListView`, `SkeletonRow`, and `CachedAsyncImage` are implemented inside the host app instead of `UIComponentsKit`.
  * Out of 15 SwiftUI View files in `myTV`, **only 1** (`myTV/Presentation/Screens/ChannelList/ChannelListView.swift:395`) includes a `#Preview`.

---

### 2.7. Automated CI/CD Enforcement, SwiftLint & Code Quality (§5.1 & §5.3)

#### ❌ Violation 17: Active Force Unwraps & Code Issues in Source, Plus `.swiftlint-baseline.json` Suppressing 52 Errors
* **Governance Rule (§3.1 & §5.3)**: *"SwiftLint Zero Tolerance: Zero warnings and zero errors allowed. `swiftlint --strict` (0 warnings, 0 errors)."*
* **What breaks it**:
  1. **Active Force Unwrapping (`!`) in `myTV/Developer/DeveloperSettingsView.swift:283-290`**:
     ```swift
     Link(destination: URL(string: "https://github.com/Anurag-Chourasia/myTV/blob/main/Docs/PrivacyInventory.md")!)
     ...
     Link(destination: URL(string: "mailto:anuragchourasiaios@gmail.com")!)
     ```
  2. **Duplicate Modifier in `myTV/Developer/DeveloperSettingsView.swift:309-310`**:
     ```swift
     .navigationBarTitleDisplayMode(.inline)
     .navigationBarTitleDisplayMode(.inline)
     ```
  3. **Baseline Suppression (`.swiftlint-baseline.json`)**:
     `.swiftlint.yml:38` configures `baseline: .swiftlint-baseline.json`, which silences **33 violations in `myTV/`** and **19 violations in `TestSupport/`** (total 52 violations).
  4. **Incomplete Custom Rule Scope in `.swiftlint.yml:41-63`**:
     The custom rules `ban_hardcoded_view_strings`, `ban_hardcoded_padding`, and `ban_hardcoded_corner_radius` only target `included: ".*/Presentation/.*"`, allowing views in `Developer/` and `Core/` to bypass architectural lint checks.

---

## 3. Complete File-by-File Violation Matrix

| File | Layer | Governance Rule Broken | Severity | Line Numbers |
| :--- | :--- | :--- | :---: | :--- |
| `myTV/App/AppDI.swift` | `App` | §4.2 Zero Ad-Hoc Network Calls (`URLSession.shared` exposed) | Medium | L18, L66–68 |
| `myTV/Developer/AppRuntime.swift` | `Developer` | §4.1 Unsanctioned layer; §3.6 Ad-hoc feature flags; §3.7 In-house `DeveloperStubRepository` instead of `AppStubData` | High | L6–69, L72–134 |
| `myTV/Developer/DeveloperSettingsView.swift` | `Developer` | §4.1 View instantiates `ChannelDiskCache()`; §3.3 Imports `AuthKitSupabase`; §3.1 Raw strings (`"Apply and close"`, `"0 channels (0 KB)"`); §3.2 `Typography.*` & `ColorTheme.default.green`; §5.1 Force unwrap `URL(...)!` & duplicate modifier | Critical | L5, L54, L156, L169, L283–290, L309–325 |
| `myTV/Core/Localization/CategoryDisplay.swift` | `Core` | §3.1 & §4.2 Zero Raw Strings Rule (30 hardcoded English category names + emojis) | Critical | L60–91 |
| `myTV/Core/ImageCaching/ImageLoader.swift` | `Core` | §4.2 Direct `URLSession.shared.data(from:)` outside `CommonNetworkingKit`/`Data`; §3.6 Raw `print()` | High | L25, L44, L60 |
| `myTV/Core/ImageCaching/CachedAsyncImage.swift` | `Core` | §4.1 SwiftUI `View` in `Core/`; §4.2 `URLSession = .shared` default param; §3.4 In-house component | High | L10–24 |
| `myTV/Core/Haptic/HapticService.swift` | `Core` | §4.1 Unnecessary `import UIKit` in pure protocol definition | Low | L9 |
| `myTV/Data/Cache/ChannelDiskCache.swift` | `Data` | §3.1 Hardcoded `"0 KB"` string in `Data`; §3.6 Raw `print()` instead of `FoundationKit` logger | Medium | L28, L38 |
| `myTV/Data/Network/Client/HTTPClient.swift` | `Data` | §4.1 Reads `UserDefaults` `"developer.httpLogs"` directly inside `Data` client init | Low | L20–21 |
| `myTV/Domain/UseCases/FetchChannelsUseCase.swift` | `Domain` | §4.1.1 Mixes query (`execute`) and command (`clearCache`) in a single Fetch UseCase | Low | L7–10 |
| `myTV/Presentation/Components/Banner/OfflineBanner.swift` | `Presentation` | §2 & §3.2 Uses `ColorTheme.default.red` instead of KeyPath color token | Medium | L11 |
| `myTV/Presentation/Components/Channel/ChannelGridView.swift` | `Presentation` | §2 `Typography.headline`/`.caption` & `LayoutPreset.compactMedia`; §3.1 `Text(String(\...))` | Medium | L23–29, L42–43 |
| `myTV/Presentation/Components/Channel/ChannelRowView.swift` | `Presentation` | §2 `Typography.headline`/`.caption`; §3.1 `Text(String(\...))` | Medium | L23–29 |
| `myTV/Presentation/Components/Channel/ChannelLogo.swift` | `Presentation` | §2 `DesignMetricTheme.default.p40` instead of KeyPath metric | Medium | L13–14 |
| `myTV/Presentation/Components/Channel/ChannelSectionHeader.swift` | `Presentation` | §2 `Typography.headline` instead of `.font(\.headline)` | Low | L16 |
| `myTV/Presentation/Components/Channel/FavoriteButton.swift` | `Presentation` | §2 `ScaleToken.p1_15` static access; §3.1 `Text(String(\...))` | Low | L28–29 |
| `myTV/Presentation/Components/Skeleton/SkeletonListView.swift` | `Presentation` | §2 `LayoutPreset.compactMedia.*`; §3.4 In-house skeleton UI | Low | L11–16 |
| `myTV/Presentation/Components/State/ErrorViewModel.swift` | `Presentation` | §3.1 Raw string key `"app.retry"` via `LocalizationController.shared.string(...)` | High | L16 |
| `myTV/Presentation/Controls/ChannelStickyBar.swift` | `Presentation` | §2 `Typography.subheadline`; §3.1 `Text(String(\...))` and `Text("")` | Medium | L19, L32 |
| `myTV/Presentation/Controls/MultiSelectView.swift` | `Presentation` | §4.1.4 Calls `AppDI.shared.getHaptics()`; §3.1 `Text(String(\...))` and `Text("")` | Medium | L26, L95 |
| `myTV/Presentation/Controls/MultiSelectViewModel.swift` | `Presentation` | §3.1 Manual string concatenation `"\(String(\MyTVStrings.search)) \(title)"` | Low | L57 |
| `myTV/Presentation/Controls/ScreenTools.swift` | `Presentation` | §4.1.4 Calls `AppDI.shared.getHaptics()` and `AppDI.shared.makeAboutViewModel()` | Medium | L14–15, L55–56 |
| `myTV/Presentation/Screens/AboutView/AboutView.swift` | `Presentation` | §3.1 `Text(String(\MyTVStrings...))` | Low | L111–112 |
| `myTV/Presentation/Screens/ChannelList/ChannelListView.swift` | `Presentation` | §4.1.4 Calls `AppDI.shared` in init; §2 `DesignMetricTheme.default.*` & `LayoutPreset.*`; §3.1 `Text(String(\...))` | High | L22–27, L157–199, L367–368 |
| `myTV/Presentation/Screens/ChannelList/ChannelListViewModel.swift` | `Presentation` | §4.1.3 Instantiates `FavoriteChannelStore()` (Data layer) and `DefaultImageCache.shared`; unused `import UIKit` | High | L10, L166–167 |
| `myTV/Presentation/Screens/StreamList/StreamListView.swift` | `Presentation` | §2 `Typography.headline`/`.caption` & `LayoutPreset.*`; §3.1 `Text(String(\...))` | Medium | L104–135 |
| `myTV/Presentation/Screens/StreamList/StreamListViewModel.swift` | `Presentation` | §4.1.3 Injects concrete `DefaultFetchStreamsForChannelUseCase`; imports `UIKit`/`AVKit`; §3.1 Raw string key `"app.ok"` | High | L18–19, L52–53, L175 |
| `myTV/Presentation/Screens/StreamPlayerView/StreamPlayerView.swift` | `Presentation` | §3.6 Raw `print()` statements instead of `FoundationKit` logger | Low | L48, L50, L58 |
| `.swiftlint.yml` & `.swiftlint-baseline.json` | CI / Config | §5.3 Baseline suppresses 52 lint errors; custom UI rules only check `Presentation/` | High | `.swiftlint.yml:38, 41–63` |

---

## 4. Prioritized Remediation Roadmap

1. **Eliminate Clean Architecture Layer Leaks (Priority 1)**:
   * Remove `private let diskCache = ChannelDiskCache()` from `DeveloperSettingsView.swift` and inject a cache-management abstraction from `AppDI`.
   * Update `StreamListViewModel.init` to accept `any FetchStreamsForChannelUseCase` instead of `DefaultFetchStreamsForChannelUseCase`.
   * Remove `FavoriteChannelStore()` and `DefaultImageCache.shared` default arguments from `ChannelListViewModel.init`, and remove `AppDI.shared` default arguments from Presentation Views (`ChannelListView`, `MultiSelectView`, `ScreenTools`).
   * Move `TVLaunchView` and `SupabaseBackendFactory.make` wiring out of `Developer/DeveloperSettingsView.swift` into `App/` (`myTVApp.swift` / `AppDI.swift`).
   * Consolidate `Core/` and `Developer/` files into the canonical `Domain/`, `Data/`, `Presentation/`, and `App/` folders.

2. **Enforce `LocalisationKit` Zero Raw Strings & KeyPath API (Priority 2)**:
   * Register the 30 category titles in `CategoryDisplay.swift` and the raw strings in `DeveloperSettingsView.swift` (`"Apply and close"`, `"0 channels (0 KB)"`) in `LocalisationKit`.
   * Replace `LocalizationController.shared.string("app.retry")` and `("app.ok")` with KeyPaths (`\.retry`, `\.ok`).
   * Replace `Text(String(\MyTVStrings...))` across all SwiftUI Views with `Text(\.keyPath)`.

3. **Adopt `DesignTokensKit` KeyPath Modifiers Exclusively (Priority 3)**:
   * Replace `.font(Typography.headline)` / `.caption` / `.subheadline` with `.font(\.headline)` / `.font(\.caption)` / `.font(\.subheadline)`.
   * Replace `ColorTheme.default.red` / `.green` and `DesignMetricTheme.default.*` with KeyPath token modifiers.

4. **Route Image Networking Through `CommonNetworkingKit` & Logging Through `FoundationKit` (Priority 4)**:
   * Refactor `ImageLoader` to fetch image data via `CommonNetworkingKit` (injected from `Data`) rather than `URLSession.shared.data(from:)`.
   * Replace all `print()` statements in `ImageLoader.swift`, `ChannelDiskCache.swift`, and `StreamPlayerView.swift` with `FoundationKit` structured logging.

5. **Burn Down `.swiftlint-baseline.json` & Expand Custom Lint Rules (Priority 5)**:
   * Fix the force-unwrapped URLs and duplicate `.navigationBarTitleDisplayMode(.inline)` in `DeveloperSettingsView.swift`.
   * Resolve the 52 suppressed baseline violations, delete `.swiftlint-baseline.json`, and remove `baseline:` from `.swiftlint.yml`.
   * Broaden `ban_hardcoded_view_strings`, `ban_hardcoded_padding`, and `ban_hardcoded_corner_radius` in `.swiftlint.yml` to cover the entire `myTV/` source tree.
