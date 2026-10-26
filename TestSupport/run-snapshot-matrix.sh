#!/bin/bash
set -euo pipefail

# Ensure DEVELOPER_DIR points to Xcode if not already configured
DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode 27.1.app/Contents/Developer}"
export DEVELOPER_DIR

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

echo "============================================================"
echo "🚀 Running Concurrent Snapshot Testing Across All Simulators"
echo "============================================================"
echo "Developer Dir : $DEVELOPER_DIR"
echo "Project Path  : $PROJECT_DIR"
echo ""

# Simulators in the Matrix:
# 1. Base Phone    : iPhone 11 (iOS 26.5)
# 2. Foldable Phone: iPhone Duo (iOS 27.1)
# 3. Standard Tablet: iPad (A16) (iPadOS 27.0)

echo "Triggering concurrent test execution on all 3 matrix destinations..."

xcrun xcodebuild test \
    -project myTV.xcodeproj \
    -scheme myTV \
    -only-testing:myTVSnapshotTests \
    -destination "platform=iOS Simulator,name=iPhone 11,OS=26.5" \
    -destination "platform=iOS Simulator,name=iPhone Duo,OS=27.1" \
    -destination "platform=iOS Simulator,name=iPad (A16),OS=27.0" \
    -onlyUsePackageVersionsFromResolvedFile \
    -disableAutomaticPackageResolution \
    -scmProvider system \
    CODE_SIGNING_ALLOWED=NO

echo ""
echo "============================================================"
echo "🎉 All simulators executed snapshots concurrently with 100% success!"
echo "============================================================"
