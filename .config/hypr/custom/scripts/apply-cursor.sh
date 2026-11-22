#!/usr/bin/env bash
# Applies the cursor theme and size the KDE settings (kcminputrc) hold, for Hyprland and for GTK apps.
theme="$(kreadconfig6 --file kcminputrc --group Mouse --key cursorTheme 2>/dev/null)"
size="$(kreadconfig6 --file kcminputrc --group Mouse --key cursorSize 2>/dev/null)"
[ -z "$theme" ] && theme="$(gsettings get org.gnome.desktop.interface cursor-theme 2>/dev/null | tr -d "'")"
[ -z "$size" ] && size="$(gsettings get org.gnome.desktop.interface cursor-size 2>/dev/null)"
[ -z "$size" ] && size=24
[ -z "$theme" ] && exit 0
hyprctl setcursor "$theme" "$size" >/dev/null 2>&1
gsettings set org.gnome.desktop.interface cursor-theme "$theme" 2>/dev/null
gsettings set org.gnome.desktop.interface cursor-size "$size" 2>/dev/null
mkdir -p "$HOME/.icons/default"
printf '[Icon Theme]\nName=Default\nInherits=%s\n' "$theme" > "$HOME/.icons/default/index.theme"
