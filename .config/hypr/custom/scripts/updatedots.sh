#!/usr/bin/env bash
cd ~/.cache/dots-hyprland/

echo "==> Checking for updates..."
git fetch

NEW_COMMITS=$(git log HEAD..origin/main --pretty=format:"%h %an %s (%ar)")

if [[ -n "$NEW_COMMITS" ]]; then
  echo "==> Updates available:"
  echo "$NEW_COMMITS"

  read -rp "==> Run git pull? [y/N] " ans
  if [[ "$ans" =~ ^[Yy]$ ]]; then
    git pull --recurse-submodules
  else
    echo "==> Skipping git pull."
  fi

  read -rp "==> Run ./install.sh? [y/N] " ans
  [[ "$ans" =~ ^[Yy]$ ]] && ./setup install || echo "==> Skipping install.sh."
else
  echo "==> Already up to date."
  read -rp "==> Run ./install.sh anyway? [y/N] " ans
  [[ "$ans" =~ ^[Yy]$ ]] && ./setup install || echo "==> Skipping install.sh."
fi

read -rp "==> Run postinstall.sh? [y/N] " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
  if [[ -x "$HOME/.config/hypr/custom/scripts/postinstall.sh" ]]; then
    echo "==> Running postinstall.sh..."
    "$HOME/.config/hypr/custom/scripts/postinstall.sh"
  else
    echo "==> No postinstall.sh found or not executable."
  fi
else
  echo "==> Skipping postinstall.sh."
fi

read -rp "==> Press Enter to close... " _
