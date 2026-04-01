#!/usr/bin/env bash
set -euo pipefail

# Repository to update
REPO_DIR="$HOME/Github/End4_custom_hypr_config"

# Edit this list to add/remove folders you want copied from $HOME into the repo.
# Paths are relative to $HOME.
SYNC_PATHS=(
  ".config/hypr/custom"
)

# Edit this list to add/remove files or folders you want excluded.
# Paths are relative to $HOME.
EXCLUDE_PATHS=(
  ".config/hypr/custom/scripts/printdotscommits.sh"
)

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
}

relpath_to_source() {
  local source_rel="$1"
  local target_rel="$2"

  case "$target_rel" in
  "$source_rel")
    printf '.\n'
    ;;
  "$source_rel"/*)
    printf '%s\n' "${target_rel#"$source_rel"/}"
    ;;
  *)
    return 1
    ;;
  esac
}

sync_one_path() {
  local rel_path="$1"
  local src="$HOME/$rel_path"
  local dst="$REPO_DIR/$rel_path"

  if [[ ! -e "$src" ]]; then
    log "Skipping missing path: $src"
    return 0
  fi

  mkdir -p "$(dirname "$dst")"

  local rsync_excludes=()
  local ex rel_ex
  for ex in "${EXCLUDE_PATHS[@]}"; do
    if rel_ex="$(relpath_to_source "$rel_path" "$ex")"; then
      if [[ "$rel_ex" != "." ]]; then
        rsync_excludes+=("--exclude=$rel_ex")
      fi
    fi
  done

  if [[ -d "$src" ]]; then
    log "Syncing directory: $rel_path"
    rsync -a --delete "${rsync_excludes[@]}" "$src/" "$dst/"
  else
    for ex in "${EXCLUDE_PATHS[@]}"; do
      if [[ "$ex" == "$rel_path" ]]; then
        log "Skipping excluded file: $rel_path"
        return 0
      fi
    done
    log "Copying file: $rel_path"
    cp -a "$src" "$dst"
  fi
}

choose_commit_message() {
  echo "Choose commit message option:"
  echo "1) Automatic (timestamp)"
  echo "2) Custom message"
  read -rp "Enter choice [1/2]: " choice

  case "$choice" in
  1 | "")
    echo "Sync dotfiles $(date '+%Y-%m-%d %H:%M:%S')"
    ;;
  2)
    read -rp "Enter your commit message: " custom_msg
    if [[ -z "$custom_msg" ]]; then
      echo "Sync dotfiles $(date '+%Y-%m-%d %H:%M:%S')"
    else
      echo "$custom_msg"
    fi
    ;;
  *)
    echo "Invalid choice, using automatic message."
    echo "Sync dotfiles $(date '+%Y-%m-%d %H:%M:%S')"
    ;;
  esac
}

main() {
  if [[ ! -d "$REPO_DIR/.git" ]]; then
    log "Error: not a git repository: $REPO_DIR"
    exit 1
  fi

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
  if [[ -z "$current_branch" ]]; then
    log "Detached HEAD detected; skipping git push."
    exit 0
  fi

  git push origin "$current_branch"
  log "Pushed to origin/$current_branch"
}

main "$@"
