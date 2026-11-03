#!/bin/bash

# @raycast.schemaVersion 1
# @raycast.title Spotlight
# @raycast.description Dim everything except a circle around the cursor. Run again to turn off.
# @raycast.mode silent
# @raycast.icon 🔦
# @raycast.packageName Screen

cd "$(dirname "$0")" || exit 1
# -x is an exact, case-sensitive name match, so macOS's own Spotlight is never touched.
pkill -x spotlight && exit 0
[ spotlight -nt spotlight.swift ] || swiftc -O spotlight.swift -o spotlight || exit 1
nohup ./spotlight >/dev/null 2>&1 &
