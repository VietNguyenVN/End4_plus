#!/usr/bin/env bash
set -euo pipefail

# Automatically detect repository root (based on script location)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR" && git rev-parse --show-toplevel 2>/dev/null || true)"

if [[ -z "$REPO_DIR" ]]; then
  echo "Error: Could not determine git repository root. Make sure this script is inside your repo."
  exit 1
fi
# Edit this list to add/remove folders you want copied from $HOME into the repo.
SYNC_PATHS=(
  ".config/hypr/custom"
  ".config/nvim/lua/plugins"
)

# Edit this list to add/remove files or folders you want excluded.
EXCLUDE_PATHS=(
  ".config/hypr/custom/scripts/printdotscommits.sh"
)

log() {
  printf '[%s] %s
' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
}

relpath_to_source() {
  local source_rel="$1"
  local target_rel="$2"

  case "$target_rel" in
  "$source_rel") printf '.
' ;;
  "$source_rel"/*) printf '%s
' "${target_rel#"$source_rel"/}" ;;
  *) return 1 ;;
  esac
}

sync_one_path() {
  local rel_path="$1"
  local src="$HOME/$rel_path"
  local dst="$REPO_DIR/$rel_path"

  [[ ! -e "$src" ]] && {
    log "Skipping missing path: $src"
    return
  }

  mkdir -p "$(dirname "$dst")"

  local rsync_excludes=()
  local ex rel_ex
  for ex in "${EXCLUDE_PATHS[@]}"; do
    if rel_ex="$(relpath_to_source "$rel_path" "$ex")"; then
      [[ "$rel_ex" != "." ]] && rsync_excludes+=("--exclude=$rel_ex")
    fi
  done

  if [[ -d "$src" ]]; then
    log "Syncing directory: $rel_path"
    rsync -a --delete "${rsync_excludes[@]}" "$src/" "$dst/"
  else
    for ex in "${EXCLUDE_PATHS[@]}"; do
      [[ "$ex" == "$rel_path" ]] && {
        log "Skipping excluded file: $rel_path"
        return
      }
    done
    log "Copying file: $rel_path"
    cp -a "$src" "$dst"
  fi
}

choose_commit_message() {
  # Send prompts to stderr so they don't get captured
  echo "Choose commit message option:" >&2
  echo "1) Automatic (timestamp)" >&2
  echo "2) Custom message" >&2
  read -rp "Enter choice [1/2]: " choice >&2

  case "$choice" in
  1 | "") echo "Sync dotfiles $(date '+%Y-%m-%d %H:%M:%S')" ;;
  2)
    read -rp "Enter your commit message: " custom_msg >&2
    [[ -z "$custom_msg" ]] && echo "Sync dotfiles $(date '+%Y-%m-%d %H:%M:%S')" || echo "$custom_msg"
    ;;
  *)
    echo "Invalid choice, using automatic message." >&2
    echo "Sync dotfiles $(date '+%Y-%m-%d %H:%M:%S')"
    ;;
  esac
}

main() {
  cd "$REPO_DIR"

  for path in "${SYNC_PATHS[@]}"; do
    sync_one_path "$path"
  done

  git add -A

  if git diff --cached --quiet; then
    log "No changes to commit."
  else
    commit_msg="$(choose_commit_message)"
    git commit -m "$commit_msg"
    log "Committed changes: $commit_msg"
  fi

  current_branch="$(git branch --show-current)"
  [[ -z "$current_branch" ]] && {
    log "Detached HEAD, skipping push."
    exit 0
  }

  if git diff --quiet HEAD origin/"$current_branch"; then
    log "No changes to push."
  else
    git push origin "$current_branch"
    log "Pushed to origin/$current_branch"
  fi
}

main "$@"
