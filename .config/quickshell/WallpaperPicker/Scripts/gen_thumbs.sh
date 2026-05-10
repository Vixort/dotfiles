#!/bin/bash

WALL_DIR="$HOME/wallpaper/"
THUMB_DIR="$WALL_DIR/thumbnails"

mkdir -p "$THUMB_DIR"

echo "Checking videos in $WALL_DIR and generating thumbnails in $THUMB_DIR..."

for video in "$WALL_DIR"/*.mp4; do
  filename=$(basename "$video" .mp4)
  thumb="$THUMB_DIR/${filename}.jpg"

  if [ ! -f "$thumb" ]; then
    echo "Create thumbnails: $filename.jpg"
    ffmpeg -hide_banner -loglevel error -i "$video" -vframes 1 -q:v 2 "$thumb" -y
  fi
done

echo "successfully generated thumbnails for all videos in $WALL_DIR"
