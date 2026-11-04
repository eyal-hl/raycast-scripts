#!/bin/bash

# @raycast.schemaVersion 1
# @raycast.title FX: Heatwave
# @raycast.description Makes the screen shimmer like hot asphalt. Needs Screen Recording for Raycast.
# @raycast.mode silent
# @raycast.icon 🥵
# @raycast.packageName Weather

cd "$(dirname "$0")" || exit 1
[ fx -nt fx.swift ] || swiftc -O fx.swift -o fx || exit 1
nohup ./fx heatwave >/dev/null 2>&1 &
