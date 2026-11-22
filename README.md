# CONFIGURATIONS AND SCRIPTS FOR END4 DOTFILES

This repository contains my Hyprland configurations for End-4 dotfiles.
It includes personalized layout tweaks, keybindings, and various utility scripts.

https://github.com/user-attachments/assets/49c4bd63-1e22-40dd-95e0-bc4c3e90a520

## end4pC C++ setup

This branch snapshots my PC configuration for the [end4pC C++ shell](https://github.com/pctrade/end4pC-cpp-beta).
Build or install the shell at `~/.config/end4pC` first. Back up your own dotfiles, then merge the files under `.config/` into `~/.config/`.
Copy `.local/share/end4pC/config.json` to the shell's data directory to restore the shell settings, and copy the preset if you want it available in Settings.
The monitor rules are for my DP-2 and HDMI-A-1 outputs. Adjust them for your hardware before reloading Hyprland.

## Meet zscroll — my own Hyprland layout

**Two windows per row, scrolling vertically.** `zscroll` is my custom Lua layout in this setup. Windows follow a Z order: left to right, then down
to the next pair. Each window takes half the width and the full height of the
available work area; focusing another row brings that pair into view.

https://github.com/user-attachments/assets/121a8c6f-5027-4235-b3d1-12acecdeb02b

- Navigate between rows with the keyboard or mouse wheel, or click the neighboring
  row peeking through the outer gaps.
- Swap windows directionally; closing or floating a window automatically repacks
  the remaining pairs. An odd final window stays on the left.
- Each workspace remembers its row position, and window groups occupy one slot.

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
