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
- Debounced search
- Multi-select filters for **Country** and **Category**
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
- No business logic inside Views

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
    │   ├── Haptic
    │   │   ├── HapticService.swift
    │   │   └── HapticServiceImpl.swift
    │   │
    │   ├── Reachability
    │   │   ├── ReachabilityService.swift
    │   │   └── ReachabilityServiceImpl.swift
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
    |   |
    │   ├── Cache
    │   │   ├── ChannelCache.swift
    │   │   └── ChannelDiskCache.swift
    │   │
    │   ├── Mappers
    │   │   ├── Channel+Mapper.swift
    │   │   └── Stream+Mapper.swift
    │   │
    │   └── Network
    │       ├── DTO
    │       │   ├── ChannelDTO.swift
    │       │   ├── LogoDTO.swift
    │       │   └── StreamDTO.swift
    │       │
    │       ├── Client
    │       │   └── IPTVAPIService.swift
    │       │
    │       ├── Endpoints
    │       │   └── IPTVEndpoint.swift
    │       │
    │       ├── Parsers
    │       │   └── HTTPClient.swift
    │       │
    │       └── Services
    │           └── M3UParser.swift
    │
    ├── Domain
    │   ├── Entities
    │   │   ├── Channel.swift
    │   │   ├── Stream.swift
    │   │   └── Category.swift
    │   │
    │   ├── Repositories
    │   │   └── ChannelRepository.swift
    │   │
    │   └── UseCases
    │       ├── DefaultFetchChannelsUseCase.swift
    │       └── DefaultFetchStreamsForChannel.swift
    │
    ├── Presentation
    │   ├── Components
    │   │   ├── Banner
    │   │   │   └── OfflineBanner.swift
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
    │   │       └── LoadingView.swift
    │   │
    │   ├── Controls
    │   │   ├── AppearanceMenu.swift
    │   │   ├── LayoutSwitchBar.swift
    │   │   ├── ChannelStickyBar.swift
    │   │   └── MultiSelectView.swift
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
    │       │   └── Localizable.strings
    │       └── Localized.generated.swift
    │
    ├── Scripts
    │   └── generate_localization.py
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
 - Dynamic Type support
 - Accessibility Support
 - Unit & UI tests
 - CI/CD pipeline
 - Snapshot testing
 - Performance profiling
 - Modularization using Swift Packages

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
