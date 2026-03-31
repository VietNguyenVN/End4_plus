#!/usr/bin/env bash

# Comfortable float sizes for 1920x1200
sizes=(
  "960 600"   # small
  "1280 800"  # medium
  "1600 1000" # large
)

state_file="/tmp/hypr_float_cycle_state"

# Get active window info
win=$(hyprctl activewindow -j)
addr=$(echo "$win" | jq -r '.address')
[ -z "$addr" ] && exit 0

is_floating=$(echo "$win" | jq -r '.floating')

if [ "$is_floating" = "false" ]; then
  # Enter float mode, start at medium (index 0)
  hyprctl dispatch togglefloating
  read -r w h <<<"${sizes[0]}"
  hyprctl dispatch resizeactive exact "$w" "$h"
  hyprctl dispatch centerwindow
  echo "$addr:0" >"$state_file"
else
  # Already floating → cycle size
  current_index=0
  if grep -q "$addr" "$state_file" 2>/dev/null; then
    current_index=$(grep "$addr" "$state_file" | cut -d: -f2)
  fi

  next_index=$((current_index + 1))

  if [ "$next_index" -ge "${#sizes[@]}" ]; then
    # 4th press → back to tiled
    hyprctl dispatch togglefloating
    rm -f "$state_file"
  else
    read -r w h <<<"${sizes[$next_index]}"
    hyprctl dispatch resizeactive exact "$w" "$h"
    hyprctl dispatch centerwindow
    echo "$addr:$next_index" >"$state_file"
  fi
fi
