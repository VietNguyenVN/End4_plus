local window_rules = {
	{
		match = { class = ".*" },
		opacity = "0.89 override 0.89 override",
		no_blur = false,
	},
	-- Keep Document Viewer mostly opaque.
	{
		match = { class = "org\\.gnome\\.Papers" },
		opacity = "0.97 override 0.97 override 1 override",
	},
	-- Keep Waydroid opaque and full-width in lua:zscroll.
	-- Apply after the global opacity and blur rules.
	{
		match = {
			class = "(?i)waydroid(\\..*)?",
		},
		tag = "zscroll-full",
		opacity = "1 override 1 override 1 override",
		no_blur = true,
	},
	{
		match = {
			class = "vesktop",
		},
		workspace = "special:vesktop",
		tag = "zscroll-full",
	},
	{
		match = {
			class = "spotify",
		},
		workspace = "special:spotify",
		tag = "zscroll-full",
	},
}

for _, rule in ipairs(window_rules) do
	hl.window_rule(rule)
end

-- These shell windows draw 36px circular corners into their own surfaces.
-- Apply the same shape to the compositor blur after the shell's rules load.
hl.on("config.reloaded", function()
	hl.window_rule({
		name = "personal-tools-blur",
		match = { class = "^end4pC-(tools|tasks)$" },
		no_blur = false,
		rounding = 36,
		rounding_power = 2,
	})
end)

require("custom.actions.display").restore_gaps()
