#!/bin/bash

# @raycast.schemaVersion 1
# @raycast.title FX: Tornado
# @raycast.description A dust funnel spins up across the screen.
# @raycast.mode silent
# @raycast.icon 🌪️
# @raycast.packageName Weather

cd "$(dirname "$0")" || exit 1
[ fx -nt fx.swift ] || swiftc -O fx.swift -o fx || exit 1
nohup ./fx tornado >/dev/null 2>&1 &
