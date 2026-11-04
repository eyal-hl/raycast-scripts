#!/bin/bash

# @raycast.schemaVersion 1
# @raycast.title FX: Bird Flock
# @raycast.description A murmuration sweeps across the screen.
# @raycast.mode silent
# @raycast.icon 🐦
# @raycast.packageName Screen

cd "$(dirname "$0")" || exit 1
[ fx -nt fx.swift ] || swiftc -O fx.swift -o fx || exit 1
nohup ./fx flock >/dev/null 2>&1 &
