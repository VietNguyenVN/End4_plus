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
		workspace = "special:vesktop",
	},
	{
		match = {
			class = "spotify",
		},
		workspace = "special:spotify",
	},
}

for _, rule in ipairs(window_rules) do
	hl.window_rule(rule)
end

-- Helper para float+center+size
local function float_center(match, size)
	local rule = { match = match, float = true, center = true }
	hl.window_rule(rule)
	if size then
		hl.window_rule({ match = match, size = size })
	end
end
-- illogical-impulse Settings
float_center({ title = "^(illogical-impulse Settings)$" }, { "(monitor_w*0.50)", "(monitor_h*0.50)" })

require("custom.actions.display").apply_gaps()
