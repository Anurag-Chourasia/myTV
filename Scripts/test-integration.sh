#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "=== [MyTV] Integration Lane: Caches, Availability, Lifecycle & RLS ==="
START_TIME=$(date +%s)

destination="${TEST_DESTINATION:-platform=iOS Simulator,name=iPhone 11}"
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
