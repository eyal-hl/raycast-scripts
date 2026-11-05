#!/bin/bash

# @raycast.schemaVersion 1
# @raycast.title FX: Countdown
# @raycast.description Huge 3, 2, 1 numbers, then your message.
# @raycast.mode silent
# @raycast.icon ⏳
# @raycast.packageName Screen
# @raycast.argument1 { "type": "text", "placeholder": "Message (Go!)", "optional": true }

cd "$(dirname "$0")" || exit 1
[ fx -nt fx.swift ] || swiftc -O fx.swift -o fx || exit 1
nohup ./fx countdown ${1:+"$1"} >/dev/null 2>&1 &
