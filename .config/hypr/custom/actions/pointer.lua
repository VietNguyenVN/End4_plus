local M = {}
local generation = 0

-- Wait until focus-following layout updates have placed the destination row.
-- Mouse clicks do not call this helper, so they keep their original position.
function M.center_after_navigation()
	generation = generation + 1
	local request = generation
	local focused = hl.get_active_window()
	local address = focused and focused.address
	if not address then return end
	hl.timer(function()
		local win = hl.get_active_window()
		if request ~= generation or not win or win.address ~= address then return end
		local at, size = win.at, win.size
		if at and size then
			hl.dispatch(hl.dsp.cursor.move({ x = at.x + size.x / 2, y = at.y + size.y / 2 }))
		end
	end, { timeout = 1, type = "oneshot" })
end

return M
