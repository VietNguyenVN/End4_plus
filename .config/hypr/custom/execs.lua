hl.on("hyprland.start", function()
	hl.exec_cmd("pgrep -x fcitx5 >/dev/null || fcitx5 -d")
	hl.exec_cmd("hyprpm reload -n")
end)
