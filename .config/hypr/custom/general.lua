-- Overrides applied after hyprland/general.lua.

-- Z-scroll slots remain full-height; center any incomplete row as a group.
local zscroll_options = {
	windows_per_row = 2,
	center_incomplete_rows = true, -- also centers 2 windows in a 3-slot row, etc.
}
require("custom.layouts.zscroll").configure(zscroll_options)

hl.config({
	scrolling = {
		fullscreen_on_one_column = false,
		column_width = 1,
		-- explicit_column_widths = "0.5, 1.0",
		direction = "down",
	},
	-- Master
	master = {
		new_status = "inherit",
	},
	-- Appearance and input
	decoration = {
		blur = {
			xray = false,
			-- Blur translucent Wayland menus, leaving faint shadows unblurred.
			popups = true,
			popups_ignorealpha = 0.2,
		},
	},
	input = {
		kb_options = "fkeys:basic_13-24",
	},
})

-- Plugin settings apply when Hyprland has registered the plugin.
if hl.plugin and hl.plugin.scrolloverview then
	hl.config({
		plugin = {
			scrolloverview = {
				scale = 0.6,
				workspace_gap = 60,
				layout = "horizontal",
				shadow = { enabled = false },
			},
		},
	})
end

for i = 1, 20 do
	hl.workspace_rule({ workspace = tostring(i), monitor = i <= 10 and "DP-2" or "HDMI-A-1", default = true })
end
