# CONFIGURATIONS AND SCRIPTS FOR END4 DOTFILES

This repository contains my Hyprland configurations for End-4 dotfiles.
It includes personalized layout tweaks, keybindings, and various utility scripts.

## Meet zscroll — my own Hyprland layout

**Two windows per row, scrolling vertically.** `zscroll` is my custom Lua layout
and the default in this setup. Windows follow a Z order: left to right, then down
to the next pair. Each window takes half the width and the full height of the
available work area; focusing another row brings that pair into view.

https://github.com/user-attachments/assets/121a8c6f-5027-4235-b3d1-12acecdeb02b

- Navigate between rows with the keyboard or mouse wheel, or click the neighboring
  row peeking through the outer gaps.
- Swap windows directionally; closing or floating a window automatically repacks
  the remaining pairs. An odd final window stays on the left.
- Each workspace remembers its row position, and window groups occupy one slot.

| Shortcut | Action |
| --- | --- |
| `SUPER + Arrow` | Focus a window in that direction |
| `SUPER + Comma` / `Period` | Next / previous row |
| `SUPER + SHIFT + Arrow` | Swap a window in that direction |
| `SUPER + Mouse wheel` | Move between rows |

Built with Hyprland's Lua layout API and checked on Hyprland 0.56.2.
Slots are fixed in size; native scrolling gestures and scrolloverview integration
are not implemented or verified for zscroll.
See the [layout source](.config/hypr/custom/layouts/zscroll.lua) and
[configuration notes](.config/hypr/custom/README.md) for details and more shortcuts.

## Features

These configurations extend the original setup with:

- My own `zscroll` layout, alongside scrolling, monocle, dwindle, and master
- Custom window rules
- Personalized keybindings
- (Some) scripts for automation
- Extended .config directory (e.g. nvim)

[NOTE]

This is an EXTREMELY PERSONAL configuration, so expect opinionated choices.

Feel free to adapt anything to your own workflow.

This setup is based on the End-4 Hyprland dotfiles: <https://github.com/end-4/dots-hyprland>
