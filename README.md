# myTV 📺

**myTV** is a production-grade IPTV browser built with **SwiftUI**, demonstrating real-world iOS engineering practices: **Clean Architecture**, **MVVM**, async data pipelines, caching, localization, and robust media playback.

This is a **portfolio-level reference application**, designed to reflect how a modern iOS app is structured and shipped in production — not a toy demo.

---

## ✨ Features

### 📺 Channel Browsing
- List and Grid layouts (user-selectable)
- Sticky scope tabs: **All Channels / Favorites**
- Grouping options:
  - Alphabetical (A–Z)
  - Country
  - Category
- Sorting controls:
  - Section sorting (Ascending / Descending)
  - Channel sorting (Ascending / Descending)
- Country and category display-name mapping (friendly labels + emoji)
- Filter and section ordering by display name for country/category
- Debounced search
- Multi-select filters for **Country** and **Category**
- Selected filters shown with checkmark indicators
- Favorites with persistent storage

---

### ▶️ Stream Playback
- Multiple streams per channel
- Full-screen `AVPlayer` playback
- Graceful handling of:
  - Invalid URLs
  - Unplayable streams
  - No working streams
  - Playback failures
- Custom close control for full-screen playback
- Loading overlay during stream preparation

---

### 🖼 Image Loading & Caching
- Custom async image loader
- In-memory image caching
- Automatic cache reuse
- Manual cache clearing via menu
- Fallback UI for failed image loads

---

### 🌍 Localization
- Fully localized UI using `Localizable.strings`
- Auto-generated localization accessors
- Structured localization namespaces:
  - App
  - Channel
  - Stream
  - About
- Easy to extend: add a string → regenerate → done

---

### ♿ Accessibility & UX
- Dynamic Type support across app screens
- App Dynamic Type clamp via `.dynamicTypeSize(.xSmall ... .accessibility2)`
- Accessibility-aware layout guard:
  - Grid auto-switches to List in accessibility text sizes
  - Alert shown when auto-switch happens
  - Alert shown if Grid is tapped while accessibility size is active
- Foreground revalidation of accessibility layout state after returning to app
- Dedicated `VoiceOver.strings` + generated `VoiceOver.generated.swift`
- Haptic feedback for key interactions
- Respects **Reduced Motion**
- Offline banner handling
- Comprehensive empty, loading, and error states

---

## ⚙️ Architecture

- **SwiftUI + MVVM**
- **Clean Architecture** with strict separation of concerns
- Dependency Injection via `AppDI`
- Async/Await networking
- Combine-based reactive pipelines
- Disk and memory caching layers
- ViewModels own view text/behavior logic

### Layering Model

```text
App
↓
Presentation
↓
Domain
↓
Data
↓
Core
```
---

## 🧱 Project Structure

```text
myTV
└── myTV
    ├── App
    │   ├── AppDI.swift
    │   └── myTVApp.swift
    │
    ├── Core
    │   ├── Extensions
    │   │   └── Bundle+AppInfo.swift
    │   │
    │   ├── Haptic
    │   │   ├── HapticService.swift
    │   │   └── HapticServiceImpl.swift
    │   │
    │   ├── Reachibility
    │   │   ├── ReachabilityService.swift
    │   │   └── ReachabilityServiceImpl.swift
    │   │
    │   ├── Localization
    │   │   ├── CountryDisplay.swift
    │   │   └── CategoryDisplay.swift
    │   │
    │   └── ImageCaching
    │       ├── ImageCache.swift
    │       ├── DefaultImageCache.swift
    │       ├── ImageLoader.swift
    │       └── CachedAsyncImage.swift
    │
    ├── Data
    │   ├── Repositories
    │   │   └── ChannelRepositoryImpl.swift
    │   │
    │   ├── Cache
    │   │   ├── ChannelCache.swift
    │   │   └── ChannelDiskCache.swift
    │   │
    │   ├── Mappers
    │   │   ├── Channel+Mapper.swift
    │   │   └── Stream+Mapper.swift
    │   │
    │   ├── Network
    │   │   ├── DTO
    │   │   │   ├── ChannelDTO.swift
    │   │   │   ├── LogoDTO.swift
    │   │   │   └── StreamDTO.swift
    │   │   │
    │   │   ├── Client
    │   │   │   └── HTTPClient.swift
    │   │   │
    │   │   ├── Endpoints
    │   │   │   └── IPTVEndpoint.swift
    │   │   │
    │   │   ├── Parsers
    │   │   │   └── M3UParser.swift
    │   │   │
    │   │   └── Services
    │   │       └── IPTVAPIService.swift
    │   │
    │   └── UseCases
    │       ├── DefaultFetchChannelsUseCase.swift
    │       └── DefaultFetchStreamsForChannelUseCase.swift
    │
    ├── Domain
    │   ├── Entities
    │   │   ├── Channel.swift
    │   │   ├── Stream.swift
    │   │   └── Category.swift
    │   │
    │   └── Repositories
    │       └── ChannelRepository.swift
    │
    ├── Presentation
    │   ├── Components
    │   │   ├── Banner
    │   │   │   ├── OfflineBanner.swift
    │   │   │   └── OfflineBannerViewModel.swift
    │   │   │
    │   │   ├── Channel
    │   │   │   ├── ChannelLogo.swift
    │   │   │   ├── ChannelRowView.swift
    │   │   │   ├── ChannelGridView.swift
    │   │   │   ├── ChannelSectionHeader.swift
    │   │   │   └── FavoriteButton.swift
    │   │   │
    │   │   ├── Effects
    │   │   │   ├── TypingEffectView.swift
    │   │   │   └── TypingEffectViewModel.swift
    │   │   │
    │   │   ├── Skeleton
    │   │   │   ├── SkeletonListView.swift
    │   │   │   └── SkeletonRow.swift
    │   │   │
    │   │   └── State
    │   │       ├── EmptyStateView.swift
    │   │       ├── ErrorView.swift
    │   │       ├── ErrorViewModel.swift
    │   │       ├── LoadingView.swift
    │   │       └── LoadingViewModel.swift
    │   │
    │   ├── Controls
    │   │   ├── AppearanceMenu.swift
    │   │   ├── AppearanceMenuViewModel.swift
    │   │   ├── LayoutSwitchBar.swift
    │   │   ├── ChannelStickyBar.swift
    │   │   ├── MultiSelectView.swift
    │   │   └── MultiSelectViewModel.swift
    │   │
    │   └── Screens
    │       ├── ChannelList
    │       │   ├── ChannelListView.swift
    │       │   └── ChannelListViewModel.swift
    │       │
    │       ├── StreamList
    │       │   ├── StreamListView.swift
    │       │   └── StreamListViewModel.swift
    │       │
    │       ├── StreamPlayerView
    │       │   └── StreamPlayerView.swift
    │       │
    │       └── AboutView
    │           ├── AboutView.swift
    │           └── AboutViewModel.swift
    │
    ├── Resources
    │   ├── Assets.xcassets
    │   └── Localization
    │       ├── Base.lproj
    │       │   ├── Localizable.strings
    │       │   └── VoiceOver.strings
    │       ├── Localizable.generated.swift
    │       └── VoiceOver.generated.swift
    │
    ├── Scripts
    │   ├── generate_localization.py
    │   └── generate_voiceover.py
    │
    └── Info.plist
```
Each top-level module has a single, well-defined responsibility.

---

## 🧪 Error & State Handling
 - Skeleton loading views
 - Empty state views
 - Retry actions
 - Offline detection
 - Safe fallbacks for all failures
 - User-friendly, localized error messaging

---

## 🧠 Data Source Disclaimer

This app does not host, stream, or redistribute any media content.

All channel metadata is sourced from the open-source project:

👉 https://github.com/iptv-org

Content availability, legality, and usage rights are the responsibility of the respective content providers.

---

## 🚧 Roadmap
- Phase 1: Core app architecture and fully functional MVP ✅
  - Implemented production-ready SwiftUI architecture (MVVM + DI)
  - Built channel listing with search, grouping, sorting, favorites, and layout switching
  - Added stream playback, image caching, offline handling, localization, and persistent preferences
- Phase 2: Dynamic Type, accessibility UX hardening, and presentation-layer refactor ✅
  - Added Dynamic Type support with app-wide clamp and accessibility-size handling
  - Enforced grid-to-list fallback with alerts for auto-switch and unavailable grid actions
  - Refactored presentation layer to move view logic/localized text into ViewModels
- Phase 3: Accessibility full support, accessibility identifiers, and Unit/UI tests
  - Add complete VoiceOver accessibility coverage for all user flows
  - Add accessibility identifiers for key UI components to enable automation
  - Add unit tests and UI tests for critical flows and regressions
- Phase 4: CI/CD pipeline and snapshot testing
  - Add CI pipeline for build, lint, and automated test execution
  - Add snapshot tests for visual regression checks
  - Add quality gates for pull requests and release readiness
- Phase 5: Performance profiling and modularization using Swift Packages
  - Profile startup/rendering/network performance and optimize bottlenecks
  - Split modules into Swift Packages for scalability and reuse
  - Improve maintainability for long-term feature growth

---

## 👨‍💻 Author

### Anurag Chourasia
   *iOS Engineer*
 - **GitHub**: https://github.com/Anurag-Chourasia
 - **LinkedIn**: https://www.linkedin.com/in/anurag-chourasia-b66710178/

---

## 📜 License

**Provided for educational and portfolio demonstration purposes only.**

---


### Debug configuration and screen controls

Debug builds start with Developer Settings. After opening MyTV, shake the device
(or use the simulator's Shake command) to present settings above the current
screen, including an open sheet. Applying settings rebuilds the channel screen
with the selected dependencies. Release builds omit this page and its fixtures.

Settings include live/local data, success/empty/offline scenarios, HTTP logging,
haptics, logo preview, channel layout, appearance, and displayed version/build.
Stub success provides two channels without remote logo or playback URLs; the
stream list is intentionally empty. Version overrides affect only the profile.

Screen options use hamburger menus. Filter selections have checkmarks and a
separate destructive Clear action. Hold a channel logo to preview it, then use
the native share button for Photos, Files, or supported installed apps. Preview,
profile, and player sheets use cross icons to close.

Validation: `python3 TestSupport/run-developer-tests.py` checks runtime policy in
Debug and Release, including offline fixtures and ignored release overrides.
On a device, check shake from the player/profile sheets, light/dark appearance,
and image sharing destinations (which depend on installed apps).
