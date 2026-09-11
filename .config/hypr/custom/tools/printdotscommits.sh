#!/usr/bin/env bash

OWNER="end-4"
REPO="dots-hyprland"
BRANCH="main"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"
API_URL="https://api.github.com/repos/${OWNER}/${REPO}/commits?sha=${BRANCH}&per_page=20"

# Colors
YELLOW="\033[1;33m"
CYAN="\033[1;36m"
GREEN="\033[1;32m"
RESET="\033[0m"

echo "==> end-4 / dots-hyprland — commits page"
echo ""

# Convert ISO date -> short relative ("2h", "3d", etc)
time_ago() {
  commit_date="$1"
  commit_ts=$(date -d "$commit_date" +%s)
  now_ts=$(date +%s)
  diff=$((now_ts - commit_ts))

  if [ $diff -lt 60 ]; then
    echo "${diff}s"
  elif [ $diff -lt 3600 ]; then
    echo "$((diff / 60))m"
  elif [ $diff -lt 86400 ]; then
    echo "$((diff / 3600))h"
  else
    echo "$((diff / 86400))d"
  fi
}

fetch_commits() {
  if [ -n "$GITHUB_TOKEN" ]; then
    auth_header="Authorization: token ${GITHUB_TOKEN}"
  else
    auth_header=""
  fi

  json=$(curl -s -H "Accept: application/vnd.github+json" \
    ${auth_header:+-H "$auth_header"} \
    "$API_URL")

  # header
  printf "%-8s %-5s %-12s %-40s\n" "SHA" "DATE" "AUTHOR" "MESSAGE"
  printf -- "-------------------------------------------------------------------------------\n"

  echo "$json" | jq -r '.[] | [.sha[0:7], .commit.author.name, .commit.author.date, (.commit.message | split("\n")[0])] | @tsv' |
    while IFS=$'\t' read -r sha author date msg; do
      rel_date=$(time_ago "$date")

      # truncate author and message
      short_author=$(echo "$author" | cut -c1-12)
      short_msg=$(echo "$msg" | cut -c1-80)

      printf "${YELLOW}%-8s${RESET} ${GREEN}%-5s${RESET} ${CYAN}%-12s${RESET} %-40s\n" \
        "$sha" "$rel_date" "$short_author" "$short_msg"
    done
}

if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq is required. Install it (e.g. pacman -S jq)."
  exit 1
fi

fetch_commits

echo
read -n 1 -s -r -p "=>> Press any key to exit..."
