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
- `tools/`: standalone Bash maintenance tools, launched from Lua shortcuts.
  `updatedots.sh` finds `postinstall.sh` alongside itself.
- `scripts/`: only the externally generated wallpaper restoration script,
  which the unchanged defaults still call.

Fcitx5, dock, and clock toggles are Lua actions. The dock/clock action uses `jq`
to transform Quickshell's JSON settings and writes the result atomically;
fcitx5 uses `pgrep`/`pkill`. These external utilities remain dependencies, but
the toggle logic no longer lives in Bash scripts.

Keep shared layout bindings in their current order: the first `rebind` removes
an inherited default, and later `bind` calls add layout-specific callbacks.
App helper functions return callbacks; requiring an action module registers no
shortcuts or startup commands.

Layout cycling changes only the active workspace, preferring an open special
workspace. The cycle groups are scrolling/lua:zscroll/monocle and dwindle/master;
switching groups selects the first layout in the group. Layout-specific shortcuts
check that workspace's tiled layout, while `general.lua` defines the global default.

`layouts/zscroll.lua` registers the `lua:zscroll` layout: a vertical tape
of full-height rows, each containing two half-width windows in Z order. New
windows append; closing or floating a window compacts the remaining pairs.
An odd final window stays half-width on the left. The focused row fills the work
area, with normal gaps, borders, and reserved panel space applied by Hyprland.
Focus from keyboard shortcuts, clicking a neighboring row, or an external window
switcher reveals that row. Newly opened tiled windows on the active workspace
receive focus and bring their row into view; background workspace launches do
not steal focus. Deferred updates use a new one-shot timer for each event burst
(Hyprland destroys one-shot timers after they fire).
Each workspace keeps its own row position while unfocused. Groups occupy one slot.

For a full-width, full-height row in zscroll, add the `zscroll-full` tag through a
normal window rule in `custom/rules.lua` (Hyprland regex matching):

```lua
-- Example
{ match = { class = "(?i)waydroid(\\..*)?" }, tag = "zscroll-full" },
```

Copy it and replace the class regex to give another app its own full-width row. Gaps and panels
are respected. A full-width window starts a new row and keeps target order; an
unpaired ordinary window before it stays half-width. Pairing resumes after it.
Up/down navigation moves by these mixed rows, and any tagged group member makes
its whole group full-width. This tag changes zscroll geometry only; other layouts
retain their existing sizing behavior. Reload the configuration after editing rules.
Your outer gaps expose the neighboring rows above/below the focused row; clicking
those visible strips selects that window and scrolls its pair into view. No extra
preview padding is added: the visible strip depends on `gaps_out` and `gaps_in`.

Z-scroll shortcuts:

- `SUPER + Comma` / `Period`: next / previous two-window row, without wrapping;
  retain the focused column where possible.
- `SUPER + Arrow`: spatial focus; up/down retain the column where possible.
- `SUPER + ALT + Comma` / `Period`: next / previous row.
- `SUPER + SHIFT + Comma` / `Period`: swap with the next / previous window.
- `SUPER + SHIFT + Arrow`: swap in that direction.
- `SUPER + mouse_up` / `mouse_down`: next / previous row (existing scroll polarity).
- `SUPER + ALT + mouse_up` / `mouse_down`: swap up / down.
- Bracket keys behave like left/right arrows, including Shift for swapping.

Z-scroll has fixed slot sizes; native scrolling's resize/consume messages do not
apply. It uses Lua target placement and row transitions, not the native scrolling
tape controller. Native scrolling gestures and scrolloverview integration are not
implemented or verified for this layout. Standard fullscreen enter/exit is handled
by Hyprland. Dragging uses the Lua layout adapter's native target ordering rather
than arbitrary drop-to-cell placement. Vertically adjacent physical monitors may
expose off-screen rows because this layout does not add viewport clipping.

To change the default, set `general.layout = "[...]"` in `general.lua` and
reload; to switch only the current workspace, use the existing layout cycle key
(`SUPER + SHIFT + F23`). Run `lua custom/tests/zscroll.lua` from this directory's
parent for geometry and navigation checks. The implementation was also checked
on Hyprland 0.56.2 with five disposable windows for scrolling, swapping, fullscreen
restore, and close/repacking behavior.

Floating-size state is per window in `$XDG_RUNTIME_DIR` (falling back to `/tmp`),
using a `v2` prefix and one-based indices. Old zero-based state files are ignored.

`tools/printdotscommits.sh` reads an optional `GITHUB_TOKEN` from its environment.
Without one it makes an unauthenticated request for the public repository.
`__restore_video_wallpaper.sh` is generated externally; leave it intact.

`SUPER + ALT + H` hides/restores the focused regular workspace's unpinned
windows. Each workspace has its own reserved `special:show-desktop-<id>` holding
workspace, so other monitors/workspaces are unaffected and restoration survives
config reloads. Open special workspaces are dismissed; pinned windows remain
visible. Restoring moves only windows still in that holding workspace, leaving
newly opened windows and windows manually moved elsewhere alone. Moving windows
out and back can change their tiling order and focus. The shortcut calls the Lua
action directly.
