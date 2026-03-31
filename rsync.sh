#!/usr/bin/env bash

set -e # exit on error

# ====== CONFIG ======
# Your dotfiles repo path
DOTFILES_DIR="$HOME/Documents/Github/End4_custom_hypr_config"

# Folders to copy (edit this list)
FOLDERS=(
  ".config/hypr/custom"
  # ".config/waybar"
  # ".config/kitty"
)

# Git commit message
COMMIT_MSG="Update dotfiles: $(date '+%Y-%m-%d %H:%M:%S')"

# ====== SCRIPT ======

echo "==> Syncing dotfiles..."

for folder in "${FOLDERS[@]}"; do
  SRC="$HOME/$folder"
  DEST="$DOTFILES_DIR/$folder"

  echo "Copying $SRC -> $DEST"

  # Create destination directory if needed
  mkdir -p "$(dirname "$DEST")"

  # Copy (rsync is safer than cp)
  rsync -av --delete "$SRC/" "$DEST/"
done

echo "==> Git add/commit/push..."

cd "$DOTFILES_DIR"

git add .

# Only commit if there are changes
if ! git diff --cached --quiet; then
  git commit -m "$COMMIT_MSG"
  git push
  echo "==> Done!"
else
  echo "==> No changes to commit."
fi
