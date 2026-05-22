local function set_env(name, value)
	hl.env(name, value)
end

for _, item in ipairs({
	{ "QT_IM_MODULE", "fcitx" },
	{ "XMODIFIERS", "@im=fcitx" },
	{ "SDL_IM_MODULE", "fcitx" },
	{ "GLFW_IM_MODULE", "ibus" },
	{ "INPUT_METHOD", "fcitx" },
	{ "EDITOR", "nvim" },
}) do
	set_env(item[1], item[2])
end

-- hl.config({ ecosystem = { enforce_permissions = true }})

hl.permission({ binary = "fcitx5-lotus-server", type = "keyboard", mode = "allow" })

-- ######## Wayland #########
-- Tearing
-- hl.env("WLR_DRM_NO_ATOMIC", "1")
-- ?
-- hl.env("WLR_NO_HARDWARE_CURSORS", "1")

-- ######## EDITOR #########
-- https://wiki.archlinux.org/title/Category:Text_editors
-- for example: vi nano nvim ...

-- set_env("XCURSOR_THEME", "Bibata-Modern-Classic")
-- set_env("XCURSOR_SIZE", "24")
