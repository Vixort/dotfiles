#!/bin/bash

VIDEO_PATH=$1
MONITOR=$(hyprctl monitors -j | jq -r '.[0].name')

notify-send "Wallpaper Picker" "Loading...: $(basename "$VIDEO_PATH")"

pkill mpvpaper 2>/dev/null
sleep 0.2

mpvpaper -o "loop --hwdec=auto --no-audio" "$MONITOR" "$VIDEO_PATH" &
