#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "=== [MyTV] Fast Lane: Static Checks & Fast Unit Tests ==="
START_TIME=$(date +%s)

# Prevent CI from recording snapshot baselines
if [[ "${CI:-}" != "" && ( "${RECORD_SNAPSHOTS:-0}" == 1 || "${SNAPSHOT_RECORD:-0}" == 1 ) ]]; then
    echo "CI cannot record snapshots" >&2; exit 1
fi

# 1. Pinned checks, token audits, and flake quarantine
echo "--> Running pinned checks, token audits, and quarantine verification..."
python3 Scripts/verify_pins.py
python3 Scripts/check_design_tokens.py
python3 Scripts/test_dependencies.py
python3 Scripts/verify_flake_quarantine.py
python3 Scripts/verify-snapshot-baselines.py

# 2. Fast adapter and developer runtime tests
echo "--> Running adapter and runtime tests..."
python3 TestSupport/run-adapter-tests.py
python3 TestSupport/run-developer-tests.py

# 3. Fast unit tests on iOS Simulator
destination="${TEST_DESTINATION:-platform=iOS Simulator,name=iPhone 11}"
result="${TEST_RESULT_PATH:-${RUNNER_TEMP:-/tmp}/MyTVFast.xcresult}"
rm -rf "$result"

echo "--> Running fast unit tests on $destination..."
xcrun xcodebuild test -project myTV.xcodeproj -scheme myTV \
    -destination "$destination" \
    -parallel-testing-enabled NO \
    -derivedDataPath "${RUNNER_TEMP:-/tmp}/MyTVDerived" \
    -resultBundlePath "$result" \
    -onlyUsePackageVersionsFromResolvedFile \
    -disableAutomaticPackageResolution \
    -scmProvider system CODE_SIGNING_ALLOWED=NO \
    -only-testing:myTVTests/AppRuntimeTests \
    -only-testing:myTVTests/DTOMapperTests \
    -only-testing:myTVTests/M3UParserTests \
    -only-testing:myTVTests/PrivacyManifestTests \
    -only-testing:myTVTests/ChannelListViewModelTests \
    -only-testing:myTVTests/StreamListViewModelTests \
    -only-testing:myTVTests/MultiSelectViewModelTests

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
echo "=== [MyTV] Fast Lane Succeeded in ${ELAPSED}s (Result: $result) ==="
