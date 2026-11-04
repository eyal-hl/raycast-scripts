#!/bin/bash

# @raycast.schemaVersion 1
# @raycast.title FX: Black Hole
# @raycast.description Swirls the screen into a black hole at the cursor. Needs Screen Recording for Raycast.
# @raycast.mode silent
# @raycast.icon 🕳️
# @raycast.packageName Screen

cd "$(dirname "$0")" || exit 1
[ fx -nt fx.swift ] || swiftc -O fx.swift -o fx || exit 1
nohup ./fx blackhole >/dev/null 2>&1 &
