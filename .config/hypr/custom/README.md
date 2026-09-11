# Custom Hyprland configuration

`../hyprland.lua` loads defaults from `hyprland/` before the custom general,
rule, and keybinding overrides. Environment overrides load earlier;
`variables.lua` is loaded by the default keybinding module.

- `general.lua`: monitors, input, layouts, animations, and plugin settings.
- `rules.lua`: window rules and workspace gap initialization.
- `keybinds.lua`: shortcut declarations and small registration helpers.
- `actions/`: callbacks for apps, layouts, floating windows, and display settings.
- `display-state.conf`: persistent refresh rate and gap values. Shortcuts update
  this data file atomically and apply the values directly. Manual edits take
  effect when the configuration is reloaded. Special workspace outer gaps are
  always 20 pixels greater than normal workspace outer gaps.
- `execs.lua`: startup commands.
- `scripts/`: shell integrations and maintenance commands. The floating and
  refresh scripts remain as compatibility entry points to the Lua actions.

Keep shared layout bindings in their current order: the first `rebind` removes
an inherited default, and later `bind` calls add layout-specific callbacks.
App helper functions return callbacks; requiring an action module registers no
shortcuts or startup commands.

Layout cycling changes only the active workspace, preferring an open special
workspace. The existing cycle groups remain scrolling/monocle and dwindle/master;
switching groups selects the first layout in the group. Layout-specific shortcuts
check that workspace's tiled layout, while `general.lua` defines the global default.

Floating-size state is per window in `$XDG_RUNTIME_DIR` (falling back to `/tmp`),
using a `v2` prefix and one-based indices. Old zero-based state files are ignored.

`printdotscommits.sh` reads an optional `GITHUB_TOKEN` from its environment.
Without one it makes an unauthenticated request for the public repository.
`__restore_video_wallpaper.sh` is generated externally; leave it intact.

`SUPER + ALT + H` hides/restores the focused regular workspace's unpinned
windows. Each workspace has its own reserved `special:show-desktop-<id>` holding
workspace, so other monitors/workspaces are unaffected and restoration survives
config reloads. Open special workspaces are dismissed; pinned windows remain
visible. Restoring moves only windows still in that holding workspace, leaving
newly opened windows and windows manually moved elsewhere alone. Moving windows
out and back can change their tiling order and focus. `scripts/showdesktop.sh`
remains available as an entry point to the same action.
