#!/bin/bash

# @raycast.schemaVersion 1
# @raycast.title FX: Glitch
# @raycast.description Tears the screen into RGB-shifted slices. Needs Screen Recording for Raycast.
# @raycast.mode silent
# @raycast.icon 📺
# @raycast.packageName Screen

cd "$(dirname "$0")" || exit 1
[ fx -nt fx.swift ] || swiftc -O fx.swift -o fx || exit 1
nohup ./fx glitch >/dev/null 2>&1 &
