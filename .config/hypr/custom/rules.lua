local window_rules = {
	{
		match = {
			class = ".*",
		},
		opacity = "0.89 override 0.89 override",
	},
	{
		match = {
			class = ".*",
		},
		no_blur = false,
	},
	{
		match = {
			class = "vesktop",
		},
		workspace = "special:1",
	},
	{
		match = {
			class = "spotify",
		},
		workspace = "special:4",
	},
}

local workspace_rules = {
	{
		workspace = "s[false]",
		gaps_out = 40,
	},
	{
		workspace = "s[true]",
		gaps_out = 60,
	},
}

for _, rule in ipairs(window_rules) do
	hl.window_rule(rule)
end

for _, rule in ipairs(workspace_rules) do
	hl.workspace_rule(rule)
end
