#!/bin/bash

# @raycast.schemaVersion 1
# @raycast.title Rain
# @raycast.mode silent
# @raycast.icon 🌧️
# @raycast.packageName Weather

cd "$(dirname "$0")" || exit 1
[ -x rain ] || swiftc -O rain.swift -o rain || exit 1
nohup ./rain >/dev/null 2>&1 &
