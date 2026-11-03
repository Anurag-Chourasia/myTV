#!/usr/bin/env python3
"""Fail before XCTest if any declared MyTV component or channel list snapshot baseline is missing (IOS-24)."""

import re
import sys
from pathlib import Path

root = Path(__file__).resolve().parents[1]
snapshots_dir = root / "myTVSnapshotTests/__Snapshots__"

# 1. Component Snapshots
component_source = root / "myTVSnapshotTests/ComponentSnapshotTests.swift"
component_text = component_source.read_text()
component_cases = re.findall(r'func (test\w+)\(\).*?named: "([^"]+)"', component_text, re.S)

if not component_cases:
    sys.exit("No component snapshot declarations found in ComponentSnapshotTests.swift")

missing = []
total_count = 0

for test, name in component_cases:
    for variant in ["light", "dark", "accessibility"]:
        total_count += 1
        baseline = snapshots_dir / "ComponentSnapshotTests" / f"{test}.{name}-{variant}.png"
        if not baseline.is_file():
            missing.append(str(baseline))

# 2. Channel List Matrix Snapshots
channel_source = root / "myTVSnapshotTests/ChannelListSnapshotTests.swift"
channel_text = channel_source.read_text()
channel_cases = re.findall(r'func (test\w+)\(\).*?on:\s*\.([a-zA-Z0-9]+).*?named:\s*"([^"]+)"', channel_text, re.S)

if not channel_cases:
    sys.exit("No channel list snapshot declarations found in ChannelListSnapshotTests.swift")

for test, device, name in channel_cases:
    suffix = ""
    if device == "iPhoneDuo":
        suffix = "-iPhoneDuo"
    elif device == "iPad":
        suffix = "-iPad"
    for variant in ["light", "dark", "accessibility"]:
        total_count += 1
        baseline = snapshots_dir / "ChannelListSnapshotTests" / f"{test}.{name}{suffix}-{variant}.png"
        if not baseline.is_file():
            missing.append(str(baseline))

if missing:
    sys.exit(f"Missing {len(missing)} reviewed snapshot baselines:\n" + "\n".join(missing[:5]))

print(f"Verified {total_count} snapshot reference baselines across iPhone 11, iPhone Duo, and iPad; visual review remains required.")
