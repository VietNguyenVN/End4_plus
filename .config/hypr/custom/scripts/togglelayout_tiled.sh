#!/bin/bash

LAYOUTS=("dwindle" "master")
current=$(hyprctl getoption general:layout | grep -oP '(?<=str: ).*')

for i in "${!LAYOUTS[@]}"; do
  if [ "${LAYOUTS[$i]}" = "$current" ]; then
    next=$(((i + 1) % 2))
    hyprctl keyword general:layout "${LAYOUTS[$next]}"
    exit 0
  fi
done

hyprctl keyword general:layout "${LAYOUTS[0]}"
