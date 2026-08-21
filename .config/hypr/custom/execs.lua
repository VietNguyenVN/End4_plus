-- hyprlang noerror false
-- You can make apps auto-start here
-- Relevant Hyprland wiki section: https://wiki.hyprland.org/Configuring/Keywords/#executing

-- Input method
hl.on("hyprland.start", function()
	hl.exec_cmd("fcitx5 -d")
	hl.exec_cmd("hyprpm reload -n")
end)
