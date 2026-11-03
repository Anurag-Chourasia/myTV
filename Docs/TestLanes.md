# MyTV Test Lanes & Execution Budgets

Last updated: 3 November 2026  
Milestone: **M5 Test lanes** (Ticket IOS-22)

## 1. Overview & Lane Architecture
MyTV structures its automated test suites into four distinct lanes to maximize pull request feedback velocity while preserving deep validation for playback stability, RLS permissions, and cache performance on merge and scheduled builds.

```
       ┌─────────────────────────────────────────────────────────────┐
       │                       Pull Request                          │
       │                                                             │
       │    ┌────────────────────────┐  ┌────────────────────────┐   │
       │    │       Fast Lane        │  │      UI Smoke Lane     │   │
       │    │   Unit tests & tokens  │  │ Complete player journey│   │
       │    │     (< 180s budget)    │  │     (< 45s budget)     │   │
       │    └────────────────────────┘  └────────────────────────┘   │
       └──────────────────────────────┬──────────────────────────────┘
                                      │
                                      ▼  Merge to main
       ┌─────────────────────────────────────────────────────────────┐
       │                Integration & Scheduled Deep Lanes           │
       │                                                             │
       │    ┌────────────────────────┐  ┌────────────────────────┐   │
       │    │    Integration Lane    │  │    Performance Lane    │   │
       │    │ Caches, Playback, RLS  │  │ M3U & Disk benchmarks  │   │
       │    │     (< 60s budget)     │  │     (< 60s budget)     │   │
       │    └────────────────────────┘  └────────────────────────┘   │
       └─────────────────────────────────────────────────────────────┘
```

---

## 2. Lane Mapping & Measured Durations

| Lane | Scope & Test Classes | Trigger | Measured Duration | Budget Target | Artifact Generated |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Fast Lane** | • Pinned checks (`verify_pins.py`)<br>• Design tokens audit (`check_design_tokens.py`)<br>• Networking adapter & runtime checks (`run-adapter-tests.py`, `run-developer-tests.py`)<br>• Fast unit tests: `AppRuntimeTests`, `DTOMapperTests`, `M3UParserTests`, `PrivacyManifestTests`, `ChannelListViewModelTests`, `StreamListViewModelTests`, `MultiSelectViewModelTests` | Every PR & Push | ~40s (warm) / ~120s (cold) | < 180s | `MyTVFast.xcresult` |
| **UI Smoke Lane** | • Complete user journey (`CompleteJourneyTests`): stream browsing, category filtering, playback callback lifecycle, and favorite toggling | Every PR & Push | ~28s | < 45s | `MyTVSmoke.xcresult` |
| **Integration Lane** | • Persistence & Disk Cache (`FavoriteChannelStoreTests`, `ChannelDiskCacheTests`)<br>• Offline resilience (`OfflineAndStaleCacheTests`)<br>• Network adapter & stream probing (`HTTPAdapterTests`, `ChannelAvailabilityTests`)<br>• Concurrency & playback state races (`PlaybackLifecycleRaceTests`, `StreamPlaybackTests`)<br>• Identity & RLS authorization (`AuthenticationLifecycleTests`, `BackendAuthorizationAndRLSTests`) | Merge to `main`, Scheduled, Dispatch | ~42s | < 60s | `MyTVIntegration.xcresult` |
| **Performance Lane** | • M3U playlist 1000-channel parsing throughput (`testM3UPlaylistParsingThroughput`: ~10ms)<br>• Channel disk cache batch write & read (`testChannelDiskCacheThroughput`: ~1ms)<br>• Favorite channel store 500-item query throughput (`testFavoriteStoreQueryThroughput`: ~0.1ms) | Merge to `main`, Scheduled, Dispatch | ~56s | < 60s | `MyTVPerformance.xcresult` |

---

## 3. CLI Script Entry Points
Developers can run any lane independently or all lanes together locally:

- **Fast Lane**: `bash Scripts/test-fast.sh`
- **UI Smoke Lane**: `bash Scripts/test-smoke.sh`
- **Integration Lane**: `bash Scripts/test-integration.sh`
- **Performance Lane**: `bash Scripts/test-performance.sh`
- **All Lanes Combined**: `bash Scripts/test-all-lanes.sh`

---

## 4. Artifact Retention & CI Diagnostics
- All test runs capture standard Xcode result bundles (`.xcresult`) via `-resultBundlePath`.
- In GitHub Actions CI, all `.xcresult` files are uploaded as run artifacts (`mytv-test-results`) using `actions/upload-artifact@v7`.
- On test failure, engineers can download the bundle and inspect failure traces, screenshots, and logs in Xcode Organizer with one click.
