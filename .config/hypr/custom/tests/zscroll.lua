-- Run from ~/.config/hypr: lua custom/tests/zscroll.lua
local provider, active
local timers = {}
local events, workspaces = {}, {}
local ctx
hl = {
	notification = { create = function() end },
	layout = { register = function(name, value)
		assert(name == "zscroll")
		provider = value
	end },
	get_active_window = function() return active end,
	get_active_special_workspace = function() return nil end,
	get_active_workspace = function() return active and active.workspace end,
	on = function(event, callback) events[event] = callback end,
	timer = function(callback)
		timers[#timers + 1] = callback
		-- Expired one-shot handles cannot rearm; callbacks must create new timers.
		return { set_timeout = function() end, set_enabled = function() end }
	end,
	dispatch = function(callback) callback() end,
	dsp = {
		focus = function(opts) return function() active = opts.window end end,
		layout = function(msg) return function()
			provider.layout_msg(ctx, msg)
			provider.recalculate(ctx)
		end end,
		window = { swap = function(opts) return function()
			local a, b
			for i, target in ipairs(ctx.targets) do
				if target.window == (opts.window or active) then a = i end
				if target.window == opts.target then b = i end
			end
			ctx.targets[a], ctx.targets[b] = ctx.targets[b], ctx.targets[a]
			provider.recalculate(ctx)
		end end },
	},
}
local zscroll = dofile("custom/layouts/zscroll.lua")
local function fire_timer()
	assert(#timers == 1, "expected one pending refresh")
	local callback = table.remove(timers, 1)
	callback()
end
local function external_focus()
	events["window.active"]()
	fire_timer()
end
local function make_context(id, count)
	local ws = { id = id, tiled_layout = "lua:zscroll" }
	workspaces[id] = ws
	local result = { area = { x = 20, y = 30, w = 1001, h = 800 }, targets = {} }
	for i = 1, count do
		result.targets[i] = {
			window = { address = id .. ":" .. i, workspace = ws, mapped = true },
			place = function(self, box) self.box = box end,
		}
	end
	return result
end
local function message(msg)
	assert(provider.layout_msg(ctx, msg) == nil)
	provider.recalculate(ctx)
end
ctx = make_context(1, 5)
active = ctx.targets[1].window
provider.recalculate(ctx)
assert(ctx.targets[1].box.x == 20 and ctx.targets[1].box.w == 500)
assert(ctx.targets[2].box.x == 520 and ctx.targets[2].box.w == 501)
assert(ctx.targets[3].box.y == 830 and ctx.targets[5].box.y == 1630)
assert(ctx.targets[5].box.w == 500 and ctx.targets[5].box.h == 800)
for i = 2, 5 do
	message("focus next")
	assert(active == ctx.targets[i].window)
	assert(ctx.targets[i].box.y == 30)
end
message("focus next")
assert(active == ctx.targets[5].window) -- no wrap
message("focus u")
assert(active == ctx.targets[3].window)
message("focus r")
assert(active == ctx.targets[4].window)
message("focus d")
assert(active == ctx.targets[5].window) -- incomplete last row
message("focus r")
assert(active == ctx.targets[5].window)
local moved = active
message("swap prev")
assert(ctx.targets[4].window == moved and ctx.targets[4].box.x == 520)
-- Closing an earlier window compacts all following pairs.
table.remove(ctx.targets, 1)
provider.recalculate(ctx)
assert(ctx.targets[3].window == moved and ctx.targets[3].box.x == 20)
-- External focus (e.g. app switcher) follows through the deferred callback.
active = ctx.targets[1].window
external_focus()
assert(ctx.targets[1].box.y == 30)
active = ctx.targets[4].window
external_focus()
local first = ctx
ctx = make_context(2, 1)
active = ctx.targets[1].window
provider.recalculate(ctx)
assert(ctx.targets[1].box.y == 30 and ctx.targets[1].box.w == 500)
-- Recalculating an unfocused workspace preserves its own row.
provider.recalculate(first)
assert(first.targets[3].box.y == 30)
-- A floating focus must not reset the camera.
ctx = first
active = { address = "floating", workspace = workspaces[1], floating = true }
external_focus()
assert(ctx.targets[3].box.y == 30)
-- Removing off-screen rows clamps the camera even without tiled focus.
table.remove(ctx.targets)
table.remove(ctx.targets)
provider.recalculate(ctx)
assert(ctx.targets[1].box.y == 30)
-- Group members focus the group's single slot.
local member = { address = "group-member", workspace = workspaces[1] }
ctx.targets[1].window.group = { members = { member } }
active = member
message("focus next")
assert(active == ctx.targets[2].window)
-- Repeated open events must create fresh timers and reveal the newest row.
ctx = make_context(3, 5)
active = ctx.targets[1].window
events["window.open"](ctx.targets[3].window)
events["window.open"](ctx.targets[5].window)
fire_timer()
assert(active == ctx.targets[5].window and ctx.targets[5].box.y == 30)
events["window.open"](ctx.targets[3].window)
fire_timer()
assert(active == ctx.targets[3].window and ctx.targets[3].box.y == 30)
-- A window closed before the timer runs must not receive focus.
events["window.open"](ctx.targets[5].window)
ctx.targets[5].window.mapped = false
fire_timer()
assert(active == ctx.targets[3].window)
-- Background opens do not steal focus; workspace switches cancel pending focus.
events["window.open"](first.targets[1].window)
assert(#timers == 0)
events["window.open"](ctx.targets[2].window)
local third = ctx
ctx = first
active = first.targets[1].window
fire_timer()
assert(active == first.targets[1].window)
ctx = third
active = ctx.targets[1].window
ctx.targets[2].window.floating = true
events["window.open"](ctx.targets[2].window)
assert(#timers == 0)
provider.recalculate({ area = ctx.area, targets = {} })
events["workspace.removed"](workspaces[1])
-- Removed-workspace userdata can outlive its underlying C++ workspace.
-- It remains truthy, but property reads (including id) return nil.
events["workspace.removed"](setmetatable({}, { __index = function() return nil end }))
events["workspace.removed"](nil)
-- Full-width rules mix with half-width pairs without overlap or reordering.
ctx = make_context(4, 6)
ctx.targets[2].window.tags = { "zscroll-full*" }
ctx.targets[5].window.tags = "other zscroll-full"
active = ctx.targets[1].window
provider.recalculate(ctx)
assert(ctx.targets[1].box.w == 500)
assert(ctx.targets[2].box.w == 1001 and ctx.targets[2].box.y == 830)
assert(ctx.targets[3].box.y == 1630 and ctx.targets[4].box.y == 1630)
assert(ctx.targets[4].box.x == 520)
assert(ctx.targets[5].box.w == 1001 and ctx.targets[5].box.y == 2430)
assert(ctx.targets[6].box.w == 500 and ctx.targets[6].box.y == 3230)
message("focus d")
assert(active == ctx.targets[2].window and ctx.targets[2].box.y == 30)
message("focus r")
assert(active == ctx.targets[2].window)
message("focus d")
message("focus r")
assert(active == ctx.targets[4].window)
message("focus d")
assert(active == ctx.targets[5].window)
message("swap next")
assert(active == ctx.targets[6].window and ctx.targets[6].box.w == 1001)
table.remove(ctx.targets, 2)
provider.recalculate(ctx)
assert(ctx.targets[1].box.y == ctx.targets[2].box.y)
assert(ctx.targets[2].box.x == 520)
-- A full-width member makes the entire native window group full-width.
ctx.targets[1].window.group = { members = { { tags = { "zscroll-full" } } } }
active = ctx.targets[1].window
provider.recalculate(ctx)
assert(ctx.targets[1].box.w == 1001)
print("PASS: geometry, navigation, swaps, removal, workspaces, groups, repeated timers, new-window focus")
print("PASS: mixed full-width rows, navigation, swaps, repacking, tagged groups")
-- Configurable capacity, adjacent-column navigation, and singleton centering.
zscroll.configure({ windows_per_row = 3, center_incomplete_rows = false })
ctx = make_context(5, 7)
active = ctx.targets[1].window
provider.recalculate(ctx)
assert(ctx.targets[1].box.w == 333 and ctx.targets[2].box.w == 334 and ctx.targets[3].box.w == 334)
assert(ctx.targets[3].box.x + ctx.targets[3].box.w == 1021)
message("focus r")
assert(active == ctx.targets[2].window)
message("focus r")
assert(active == ctx.targets[3].window)
message("focus d")
assert(active == ctx.targets[6].window)
message("focus d")
assert(active == ctx.targets[7].window)
assert(ctx.targets[7].box.x == 20 and ctx.targets[7].box.w == 333)
zscroll.configure({ windows_per_row = 3, center_incomplete_rows = true })
provider.recalculate(ctx)
assert(ctx.targets[7].box.x == 354 and ctx.targets[7].box.w == 333)
-- Center a singleton before a full-width row too; two of three slots are centered together.
ctx.targets[2].window.tags = { "zscroll-full" }
provider.recalculate(ctx)
assert(ctx.targets[1].box.x == 354 and ctx.targets[2].box.w == 1001)
assert(ctx.targets[6].box.x == 187 and ctx.targets[7].box.x == 520)
zscroll.configure({ windows_per_row = 1, center_incomplete_rows = true })
provider.recalculate(ctx)
for _, target in ipairs(ctx.targets) do assert(target.box.w == 1001 and target.box.x == 20) end
assert(not pcall(zscroll.configure, { windows_per_row = 0, center_incomplete_rows = false }))
assert(not pcall(zscroll.configure, { windows_per_row = 1.5, center_incomplete_rows = false }))
assert(not pcall(zscroll.configure, { windows_per_row = 2, center_incomplete_rows = "yes" }))
print("PASS: configurable row capacity, centered singletons, mixed rows, option validation")
-- Runtime capacity changes clamp at one.
zscroll.configure({ windows_per_row = 2, center_incomplete_rows = false })
ctx = make_context(6, 4)
active = ctx.targets[1].window
message("capacity -1")
assert(ctx.targets[1].box.w == 1001 and ctx.targets[2].box.y == 830)
message("capacity -1")
assert(ctx.targets[1].box.w == 1001)
message("capacity +1")
assert(ctx.targets[1].box.w == 500 and ctx.targets[2].box.y == 30)
print("PASS: capacity shortcuts and minimum row capacity")

-- Keyboard resizing changes only the focused row and preserves centering.
zscroll.configure({ windows_per_row = 3, center_incomplete_rows = true })
ctx = make_context(8, 5)
active = ctx.targets[4].window
provider.recalculate(ctx)
local before = ctx.targets[4].box.w
message("resize +0.05")
assert(ctx.targets[4].box.w > before and ctx.targets[5].box.w < 334)
assert(ctx.targets[1].box.w == 333)
local left = ctx.targets[4].box.x - ctx.area.x
local right = ctx.area.x + ctx.area.w - ctx.targets[5].box.x - ctx.targets[5].box.w
assert(math.abs(left - right) <= 1)
local grown = ctx.targets[4].box.w
message("focus u")
message("focus d")
assert(ctx.targets[4].box.w == grown)
for _ = 1, 30 do message("resize -0.05") end
assert(ctx.targets[4].box.w >= 120)
for _ = 1, 40 do message("resize +0.05") end
assert(ctx.targets[5].box.w >= 120)
ctx.targets[4].window.tags = { "zscroll-full" }
message("resize -0.05")
assert(ctx.targets[4].box.w == 1001)
message("capacity +1")
assert(ctx.targets[1].box.w == 250)
print("PASS: centered partial rows, keyboard resizing, width limits, full-width rules, reset")
-- Whole-row movement preserves groups, focus, widths, and incomplete rows.
zscroll.configure({ windows_per_row = 2, center_incomplete_rows = true })
ctx = make_context(9, 5)
local original = {}
for i, target in ipairs(ctx.targets) do original[i] = target end
active = original[1].window
provider.recalculate(ctx)
message("resize +0.05")
local resized_width = original[1].box.w
message("swaprow d")
assert(ctx.targets[1] == original[3] and ctx.targets[2] == original[4])
assert(ctx.targets[3] == original[1] and ctx.targets[4] == original[2])
assert(active == original[1].window and original[1].box.w == resized_width)
message("swaprow d")
assert(ctx.targets[3] == original[5] and ctx.targets[4] == original[1])
assert(original[1].box.y == original[2].box.y and original[5].box.y < original[1].box.y)
assert(original[5].box.x > ctx.area.x) -- singleton remains centered
message("swaprow d") -- last row does not wrap
assert(ctx.targets[4] == original[1])
message("swaprow u")
message("swaprow u")
assert(ctx.targets[1] == original[1] and ctx.targets[2] == original[2])
assert(original[1].box.w == resized_width)
message("swaprow u") -- first row does not wrap
assert(ctx.targets[1] == original[1])
-- Full-width row and a three-window row move without mixing members.
zscroll.configure({ windows_per_row = 3, center_incomplete_rows = true })
ctx = make_context(10, 5)
original = {}
for i, target in ipairs(ctx.targets) do original[i] = target end
original[4].window.tags = { "zscroll-full" }
active = original[4].window
provider.recalculate(ctx)
message("swaprow u")
assert(ctx.targets[1] == original[4] and original[4].box.w == 1001)
assert(original[1].box.y == original[2].box.y and original[2].box.y == original[3].box.y)
message("swaprow d")
assert(ctx.targets[4] == original[4])
message("swaprow d")
assert(ctx.targets[5] == original[4] and original[5].box.y < original[4].box.y)
print("PASS: whole-row swaps, partial/full-width rows, focus, preserved widths, boundaries")
