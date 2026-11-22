-- Wayland
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- Applications
local data_dirs = {
	os.getenv("HOME") .. "/.local/share/flatpak/exports/share",
	"/var/lib/flatpak/exports/share",
	"/usr/local/share",
	"/usr/share",
}
local seen = {}
for _, dir in ipairs(data_dirs) do
	seen[dir] = true
end
-- Ignore unexpanded entries inherited from the old session.
for dir in (os.getenv("XDG_DATA_DIRS") or ""):gmatch("[^:]+") do
	if dir:sub(1, 1) == "/" and not seen[dir] then
		data_dirs[#data_dirs + 1] = dir
		seen[dir] = true
	end
end
hl.env("XDG_DATA_DIRS", table.concat(data_dirs, ":"))
-- Themes
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "kde")
hl.env("XDG_MENU_PREFIX", "plasma-")

-- Virtual environment
