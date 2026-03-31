#!/usr/bin/env bash

MONITOR="eDP-1"
CONFIG="$HOME/.config/hypr/custom/general.conf"

# Query current refresh rate
CURRENT=$(hyprctl monitors -j | jq -r ".[] | select(.name==\"$MONITOR\") | .refreshRate")
RATE=$(printf "%.0f" "$CURRENT")

if [[ "$RATE" == "120" ]]; then
  NEW=60
else
  NEW=120
fi

# Update config file
sed -i \
  -e "s/^monitor=eDP-1,.*/monitor=eDP-1,1920x1200@${NEW},auto,1,transform,0/" \
  -e "s/^monitor=DP-1,.*/monitor=DP-1,1920x1200@60,1920x0,1,mirror,eDP-1/" \
  "$CONFIG"

# Optional notification
if command -v notify-send >/dev/null; then
  notify-send "Hyprland Refresh Rate" "eDP-1 switched to ${NEW}Hz"
fi
