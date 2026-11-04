#!/bin/bash

# @raycast.schemaVersion 1
# @raycast.title God Rays
# @raycast.mode silent
# @raycast.icon ☀️
# @raycast.packageName Weather

cd "$(dirname "$0")" || exit 1
[ rain -nt rain.swift ] || swiftc -O rain.swift -o rain || exit 1
nohup ./rain rays >/dev/null 2>&1 &
