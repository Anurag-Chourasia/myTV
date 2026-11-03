#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "=== [MyTV] UI Smoke Lane: Complete Playback & Favorites Journey ==="
START_TIME=$(date +%s)

destination="${TEST_DESTINATION:-platform=iOS Simulator,name=iPhone 11}"
result="${TEST_RESULT_PATH:-${RUNNER_TEMP:-/tmp}/MyTVSmoke.xcresult}"
rm -rf "$result"

echo "--> Running UI smoke tests on $destination..."
xcrun xcodebuild test -project myTV.xcodeproj -scheme myTV \
    -destination "$destination" \
    -parallel-testing-enabled NO \
    -derivedDataPath "${RUNNER_TEMP:-/tmp}/MyTVDerived" \
    -resultBundlePath "$result" \
    -onlyUsePackageVersionsFromResolvedFile \
    -disableAutomaticPackageResolution \
    -scmProvider system CODE_SIGNING_ALLOWED=NO \
    -only-testing:myTVTests/CompleteJourneyTests

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
echo "=== [MyTV] UI Smoke Lane Succeeded in ${ELAPSED}s (Result: $result) ==="
