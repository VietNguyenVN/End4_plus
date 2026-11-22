#!/usr/bin/env bash
set -o pipefail

show_commits() {
  local headers=(-H 'Accept: application/vnd.github+json')
  if [[ -n ${GITHUB_TOKEN:-} ]]; then
    headers+=(-H "Authorization: Bearer $GITHUB_TOKEN")
  fi

  printf 'Recent commits from pctrade/end4pC-cpp-beta (main)\n\n'
  curl --fail --silent --show-error --max-time 15 "${headers[@]}" \
    'https://api.github.com/repos/pctrade/end4pC-cpp-beta/commits?sha=main&per_page=20' |
    jq -r '
      def age:
        ((now - fromdateiso8601) | floor | if . < 0 then 0 else . end) as $seconds
        | if $seconds < 60 then "\($seconds)s"
          elif $seconds < 3600 then "\($seconds / 60 | floor)m"
          elif $seconds < 86400 then "\($seconds / 3600 | floor)h"
          else "\($seconds / 86400 | floor)d"
          end;
      ["SHA", "AGE", "AUTHOR", "MESSAGE"],
      (.[] | [
        .sha[:7],
        (.commit.author.date | age),
        ((.commit.author.name // "Unknown")[:12]),
        ((.commit.message | split("\n")[0])[:80])
      ]) | @tsv
    ' | column -t -s $'\t'
}

show_commits
result=$?
if (( result != 0 )); then
  printf '\nCould not load commits.\n' >&2
fi
read -r -p $'\nPress Enter to close this window… '
exit "$result"
