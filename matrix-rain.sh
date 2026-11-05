#!/bin/bash

# @raycast.schemaVersion 1
# @raycast.title FX: Matrix Rain
# @raycast.description Green glyph columns pour down the screen.
# @raycast.mode silent
# @raycast.icon 💊
# @raycast.packageName Screen

cd "$(dirname "$0")" || exit 1
[ fx -nt fx.swift ] || swiftc -O fx.swift -o fx || exit 1
nohup ./fx matrix >/dev/null 2>&1 &
