#!/usr/bin/env fish

set -l repo "$HOME/.config/end4pC"
set -l stash_before (git -C "$repo" rev-parse --verify --quiet refs/stash)

"$repo/build/end4pC" update
set -l update_status $status

if test $update_status -eq 0
    set -l stash_after (git -C "$repo" rev-parse --verify --quiet refs/stash)
    set -l stash_subject (git -C "$repo" log -g -1 --format=%gs refs/stash 2>/dev/null)
    if test -n "$stash_after"; and test "$stash_after" != "$stash_before"; and string match -q '*: end4pC update *' -- "$stash_subject"
        printf '\n'
        read --prompt-str 'Restore the local changes saved by this update (git stash pop)? [y/N] ' answer
        switch "$answer"
            case y Y yes YES
                set -l latest_stash (git -C "$repo" rev-parse --verify --quiet refs/stash)
                if test "$latest_stash" = "$stash_after"
                    git -C "$repo" stash pop 'stash@{0}'
                    set update_status $status
                else
                    printf 'The stash list changed. Review it with git stash list before restoring.\n'
                    set update_status 1
                end
            case '*'
                printf 'Local changes left in the stash.\n'
        end
    end
else
    printf '\nThe updater exited with status %d.\n' $update_status
end

printf '\n'
read --local --prompt-str 'Press Enter to close this window… ' close_input
exit $update_status
