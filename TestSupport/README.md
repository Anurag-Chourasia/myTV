# Integration validation

Run from repository root with Xcode 27.0 selected:

- `python3 TestSupport/run-adapter-tests.py`: five offline comparisons of the actual adapter against the retained pre-migration URLSession implementation. Session-scoped URLProtocol, no live endpoints.
- `bash TestSupport/check-actor-boundary.sh DERIVED_DATA`: strict iOS 16.6 compiler probe using actual DTOs and adapter under the app's MainActor/approachable-concurrency flags.
- `python3 Scripts/verify_pins.py`: exact version and full SHA validation.

MyTV has no app XCTest target. These are standalone adapter tests and compiler probes, not app UI tests. LegacyHTTPClient is validation-only and not part of the app target.

FoundationKit trims existing category display input exactly as before. LocalizationKit remains linked but unused: its Localizable-only lookup and simplified plural rules do not replace the existing generated tables safely. No unused import is added. Generated strings/resources remain app-owned.
