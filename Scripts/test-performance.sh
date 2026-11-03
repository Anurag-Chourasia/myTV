#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "=== [MyTV] Performance Lane: Playlist & Cache Throughput Baselines ==="
START_TIME=$(date +%s)

destination="${TEST_DESTINATION:-platform=iOS Simulator,name=iPhone 11}"
result="${TEST_RESULT_PATH:-${RUNNER_TEMP:-/tmp}/MyTVPerformance.xcresult}"
rm -rf "$result"

echo "--> Running performance benchmarks on $destination..."
xcrun xcodebuild test -project myTV.xcodeproj -scheme myTV \
    -destination "$destination" \
    -parallel-testing-enabled NO \
    -derivedDataPath "${RUNNER_TEMP:-/tmp}/MyTVDerived" \
    -resultBundlePath "$result" \
    -onlyUsePackageVersionsFromResolvedFile \
    -disableAutomaticPackageResolution \
    -scmProvider system CODE_SIGNING_ALLOWED=NO \
    -only-testing:myTVTests/PerformanceTests

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
echo "=== [MyTV] Performance Lane Succeeded in ${ELAPSED}s (Result: $result) ==="
