#!/usr/bin/env bash

if pgrep -x fcitx5 >/dev/null; then
  pkill -x fcitx5
else
  fcitx5 -d
fi
