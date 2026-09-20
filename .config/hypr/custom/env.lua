for _, item in ipairs({
	{ "QT_IM_MODULE", "fcitx" },
	{ "XMODIFIERS", "@im=fcitx" },
	{ "SDL_IM_MODULE", "fcitx" },
	{ "GLFW_IM_MODULE", "ibus" },
	{ "INPUT_METHOD", "fcitx" },
	{ "EDITOR", "nvim" },
	{ "QSG_RHI_BACKEND", "vulkan" },
}) do
	hl.env(item[1], item[2])
end

-- hl.config({ ecosystem = { enforce_permissions = true }})

hl.permission({ binary = "fcitx5-lotus-server", type = "keyboard", mode = "allow" })
