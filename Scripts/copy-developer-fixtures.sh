#!/bin/sh
set -eu
fixture_directory="$TARGET_BUILD_DIR/$UNLOCALIZED_RESOURCES_FOLDER_PATH/DeveloperFixtures"
if [ "$CONFIGURATION" = "Debug" ]; then
    mkdir -p "$fixture_directory"
    cp "$SRCROOT/Submodules/AppStubData/Sources/AppStubData/Resources/mytv-developer-catalog.json" "$fixture_directory/mytv-developer-catalog.json"
else
    rm -rf "$fixture_directory"
fi
