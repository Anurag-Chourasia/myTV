# Integration validation

Run from repository root with Xcode 27.1 selected:

- `python3 TestSupport/run-adapter-tests.py`: five offline comparisons of the actual adapter against the retained pre-migration URLSession implementation. Session-scoped URLProtocol, no live endpoints.
- `bash TestSupport/check-actor-boundary.sh DERIVED_DATA`: strict iOS 16.6 compiler probe using actual DTOs and adapter under the app's MainActor/approachable-concurrency flags.
- `python3 TestSupport/run-playback-tests.py`: three macOS tests of the actual playback view model with generated local audio. Covers queued failures after dismissal/replacement and current-item fallback/exhaustion. Display dependencies and services use test doubles; this does not validate device audio routing or the player UI.
- `python3 TestSupport/run-developer-tests.py`: actual runtime policy and fixture repository in Debug and Release; verifies that Release ignores developer overrides.
- `python3 TestSupport/run-channel-availability-tests.py`: actual repository with fake API responses; covers one catalog-wide lookup, missing streams, unknown availability on failure, and cancellation.
- `python3 TestSupport/run-favorites-tests.py`: stable-ID persistence, removal, and corrupt preferences.
- `python3 Scripts/verify_pins.py`: exact version and full SHA validation.

MyTV has no app XCTest target. These are standalone adapter tests and compiler probes, not app UI tests. LegacyHTTPClient is validation-only and not part of the app target.

FoundationKit trims existing category display input exactly as before. LocalizationKit remains linked but unused: its Localizable-only lookup and simplified plural rules do not replace the existing generated tables safely. No unused import is added. Generated strings/resources remain app-owned.

## Shared catalog design

CatalogTile and CatalogLayoutMenu come from UIComponentsKit 1.2.0; their metrics, colors and typography come from DesignTokensKit 1.2.0. Run `python3 Scripts/check_design_tokens.py` before submitting UI changes. CI rejects raw visual literals and implicit padding in application Swift sources. Numeric business data and conversion algorithms remain local. The scan is a source-pattern guard, not a Swift type checker.

## Private developer profile module

DeveloperProfileKit 1.0.0 owns the developer portrait, biography, social assets/links, expandable summary and app-information/disclaimer presentation. Apps supply their own name/version/build/disclaimer and navigation. The package uses the existing exact DesignTokensKit/UIComponentsKit versions. The app dependency record and Xcode lockfile verify the package commit.

The repository is private. Local builds need an authorized GitHub account with read access; CI uses a dedicated read-only deploy key stored as DEVELOPERPROFILEKIT_DEPLOY_KEY. The existing trusted-workflow SSH configuration routes only this repository through that key and removes temporary credentials after the run. No private keys are committed.

## HTTP logging

Verbose HTTP request/response logging is compiled only in Debug and disabled by default.
Use the Debug Developer Settings toggle for redacted bodies. The stored toggle takes precedence over `HTTP_LOGGING=1`, which remains an environment fallback.
Remove or disable that variable for normal testing; no HTTP body formatting or console output occurs when logging is off. Release always uses a nil logger, even if the variable is set.


## Manual interaction coverage

Debug starts with Developer Settings; shake reopens it above the current screen or
sheet. Applying or dismissing it rebuilds the channel presentation. Fixture success
contains two channels with no remote image/playback URLs; it does not validate
AVPlayer startup. The full app Release build is a separate check from the runtime
package's Release test configuration.

Check list/grid subtitles and the hide-unavailable filter together: confirmed false
availability is hidden, unknown availability remains visible, and Clear Filters
resets the toggle. Check native logo sharing, profile/player close controls, and
shake presentation on a device. These interactions are not covered by an app UI-test target.


## Private package access in CI

All six shared package repositories are private. The trusted CI workflow supplies
repository-specific read-only deploy keys through these Actions secrets:

- `COMMONNETWORKING_DEPLOY_KEY`
- `DESIGNTOKENSKIT_DEPLOY_KEY`
- `DEVELOPERPROFILEKIT_DEPLOY_KEY`
- `FOUNDATIONKIT_DEPLOY_KEY`
- `LOCALIZATIONKIT_DEPLOY_KEY`
- `UICOMPONENTSKIT_DEPLOY_KEY`

`Scripts/configure-private-dependencies.sh` writes temporary restricted-permission
key files and isolated Git/SSH configuration. Each HTTPS package URL is rewritten
to its own SSH host alias. Host keys are verified against the checked-in known-hosts
file, interactive authentication is disabled, and missing secrets fail immediately.
The workflow removes temporary credentials in its always-run cleanup step. New keys
for CommonNetworking, DesignTokensKit, and UIComponentsKit are unique per consuming
app and grant no push access. Local Xcode builds still require an authorized account.
