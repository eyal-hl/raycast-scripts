#!/bin/bash

# @raycast.schemaVersion 1
# @raycast.title Money Rain
# @raycast.mode silent
# @raycast.icon 💸
# @raycast.packageName Weather

cd "$(dirname "$0")" || exit 1
[ rain -nt rain.swift ] || swiftc -O rain.swift -o rain || exit 1
nohup ./rain money >/dev/null 2>&1 &
