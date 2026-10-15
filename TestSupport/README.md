# Integration validation

Run from repository root with Xcode 27.1 selected:

- `python3 TestSupport/run-adapter-tests.py`: five offline comparisons of the actual adapter against the retained pre-migration URLSession implementation. Session-scoped URLProtocol, no live endpoints.
- `bash TestSupport/check-actor-boundary.sh DERIVED_DATA`: strict iOS 16.6 compiler probe using actual DTOs and adapter under the app's MainActor/approachable-concurrency flags.
- `python3 TestSupport/run-playback-tests.py`: three macOS tests of the actual playback view model with generated local audio. Covers queued failures after dismissal/replacement and current-item fallback/exhaustion. Display dependencies and services use test doubles; this does not validate device audio routing or the player UI.
- `python3 Scripts/verify_pins.py`: exact version and full SHA validation.

MyTV has no app XCTest target. These are standalone adapter tests and compiler probes, not app UI tests. LegacyHTTPClient is validation-only and not part of the app target.

FoundationKit trims existing category display input exactly as before. LocalizationKit remains linked but unused: its Localizable-only lookup and simplified plural rules do not replace the existing generated tables safely. No unused import is added. Generated strings/resources remain app-owned.

## Shared catalog design

CatalogTile and CatalogLayoutMenu come from UIComponentsKit 1.2.0; their metrics, colors and typography come from DesignTokensKit 1.2.0. Run `python3 Scripts/check_design_tokens.py` before submitting UI changes. CI rejects raw visual literals and implicit padding in application Swift sources. Numeric business data and conversion algorithms remain local. The scan is a source-pattern guard, not a Swift type checker.
