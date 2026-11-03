#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "=== [MyTV] Integration Lane: Caches, Availability, Lifecycle & RLS ==="
START_TIME=$(date +%s)

# Prevent CI from recording snapshot baselines
if [[ "${CI:-}" != "" && ( "${RECORD_SNAPSHOTS:-0}" == 1 || "${SNAPSHOT_RECORD:-0}" == 1 ) ]]; then
    echo "CI cannot record snapshots" >&2; exit 1
fi
python3 Scripts/verify-snapshot-baselines.py

destination="${TEST_DESTINATION:-platform=iOS Simulator,name=iPhone 11,OS=27.0}"
result="${TEST_RESULT_PATH:-${RUNNER_TEMP:-/tmp}/MyTVIntegration.xcresult}"
rm -rf "$result"

echo "--> Running integration tests on $destination..."
xcrun xcodebuild test -project myTV.xcodeproj -scheme myTV \
    -destination "$destination" \
    -parallel-testing-enabled NO \
    -derivedDataPath "${RUNNER_TEMP:-/tmp}/MyTVDerived" \
    -resultBundlePath "$result" \
    -onlyUsePackageVersionsFromResolvedFile \
    -disableAutomaticPackageResolution \
    -scmProvider system CODE_SIGNING_ALLOWED=NO \
    -only-testing:myTVTests/FavoriteChannelStoreTests \
    -only-testing:myTVTests/ChannelDiskCacheTests \
    -only-testing:myTVTests/OfflineAndStaleCacheTests \
    -only-testing:myTVTests/HTTPAdapterTests \
    -only-testing:myTVTests/ChannelAvailabilityTests \
    -only-testing:myTVTests/PlaybackLifecycleRaceTests \
    -only-testing:myTVTests/RiskBasedIsolationAndConcurrencyTests \
    -only-testing:myTVTests/StreamPlaybackTests \
    -only-testing:myTVTests/AuthenticationLifecycleTests \
    -only-testing:myTVTests/BackendAuthorizationAndRLSTests

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
echo "=== [MyTV] Integration Lane Succeeded in ${ELAPSED}s (Result: $result) ==="
