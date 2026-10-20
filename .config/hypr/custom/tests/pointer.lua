-- Run from ~/.config/hypr: lua custom/tests/pointer.lua
local callbacks, moves = {}, {}
local active = { address = "a", at = { x = 10, y = 20 }, size = { x = 100, y = 200 } }
hl = {
	get_active_window = function() return active end,
	timer = function(callback) callbacks[#callbacks + 1] = callback end,
	dispatch = function(callback) callback() end,
	dsp = { cursor = { move = function(pos) return function() moves[#moves + 1] = pos end end } },
}
local pointer = require("custom.actions.pointer")
pointer.center_after_navigation()
assert(#moves == 0)
-- Center the final geometry, after layout placement has completed.
active.at.y = 40
table.remove(callbacks, 1)()
assert(moves[1].x == 60 and moves[1].y == 140)
pointer.center_after_navigation()
active = { address = "b", at = { x = 200, y = 50 }, size = { x = 80, y = 100 } }
table.remove(callbacks, 1)()
assert(#moves == 1) -- do not warp after unrelated focus changes
pointer.center_after_navigation()
pointer.center_after_navigation()
table.remove(callbacks, 1)()
assert(#moves == 1)
table.remove(callbacks, 1)()
assert(#moves == 2 and moves[2].x == 240 and moves[2].y == 100)
active = nil
pointer.center_after_navigation()
assert(#callbacks == 0)
print("PASS: deferred pointer centering, final geometry, focus changes, coalescing")
