-- Two half-width, full-height windows per row on a vertical tape.
-- Hyprland owns target order; new targets append and removals compact it.
local NAME = "lua:zscroll"
local rows = {}
local M = {}

local function workspace_of(ctx)
	for _, target in ipairs(ctx.targets) do
		local win = target.window
		if win and win.workspace then
			return win.workspace
		end
	end
end

local function focused_index(ctx)
	local active = hl.get_active_window()
	if not active or active.floating then
		return nil
	end
	for i, target in ipairs(ctx.targets) do
		local win = target.window
		if win then
			if win.address == active.address then
				return i
			end
			-- A group is one layout target, even when another member has focus.
			if win.group then
				for _, member in ipairs(win.group.members or {}) do
					if member.address == active.address then
						return i
					end
				end
			end
		end
	end
end

local function recalculate(ctx)
	local workspace = workspace_of(ctx)
	if not workspace or #ctx.targets == 0 then
		return
	end
	local i = focused_index(ctx)
	local row = i and math.floor((i - 1) / 2) or (rows[workspace.id] or 0)
	row = math.max(0, math.min(row, math.floor((#ctx.targets - 1) / 2)))
	rows[workspace.id] = row
	local area = ctx.area
	-- Keep pixel boundaries shared on monitors with an odd logical width.
	local left_width = math.floor(area.w / 2)
	for index, target in ipairs(ctx.targets) do
		local column = (index - 1) % 2
		target:place({
			x = area.x + (column == 1 and left_width or 0),
			y = area.y + (math.floor((index - 1) / 2) - row) * area.h,
			w = column == 0 and left_width or area.w - left_width,
			h = area.h,
		})
	end
end

local function destination(i, n, direction)
	if direction == "next" then
		return math.min(i + 1, n)
	elseif direction == "prev" then
		return math.max(i - 1, 1)
	elseif direction == "l" then
		return i % 2 == 0 and i - 1 or i
	elseif direction == "r" then
		return i % 2 == 1 and math.min(i + 1, n) or i
	elseif direction == "u" then
		return i > 2 and i - 2 or i
	elseif direction == "d" then
		return math.floor((i - 1) / 2) < math.floor((n - 1) / 2) and math.min(i + 2, n) or i
	end
end

local function layout_msg(ctx, msg)
	if msg == "refresh" then
		return -- Hyprland calls recalculate after layout_msg returns.
	end
	local action, direction = msg:match("^(%S+)%s+(%S+)$")
	if action ~= "focus" and action ~= "swap" then
		return "zscroll: expected focus/swap next|prev|l|r|u|d, or refresh"
	end
	local i = focused_index(ctx)
	if not i then
		return
	end
	local next_index = destination(i, #ctx.targets, direction)
	if not next_index then
		return "zscroll: unknown direction " .. tostring(direction)
	end
	if next_index == i then
		return
	end
	local win = ctx.targets[next_index].window
	if not win then
		return
	end
	if action == "swap" then
		-- Swap the actual layout targets, keeping native drag/swap order coherent.
		hl.dispatch(hl.dsp.window.swap({ target = win }))
	else
		hl.dispatch(hl.dsp.focus({ window = win }))
	end
end

hl.layout.register("zscroll", { recalculate = recalculate, layout_msg = layout_msg })

local function active_workspace()
	return hl.get_active_special_workspace() or hl.get_active_workspace()
end

-- Focus events can run during window creation. Defer until target insertion
-- finishes, and coalesce bursts to avoid re-entering the layout callback.
local pending_open
local refresh_timer
local function refresh()
	refresh_timer = nil
	local workspace = active_workspace()
	local win = pending_open
	pending_open = nil
	if win and win.mapped and not win.floating and win.workspace and workspace
		and win.workspace.id == workspace.id and workspace.tiled_layout == NAME then
		hl.dispatch(hl.dsp.focus({ window = win }))
	end
	if workspace and workspace.tiled_layout == NAME then
		hl.dispatch(hl.dsp.layout("refresh"))
	end
end

local function queue_refresh()
	-- One-shot timers are destroyed after firing in Hyprland 0.56; their
	-- handles cannot be rearmed. Create a fresh one for each event burst.
	if not refresh_timer then
		refresh_timer = hl.timer(refresh, { timeout = 1, type = "oneshot" })
	end
end

hl.on("window.open", function(win)
	local workspace = active_workspace()
	-- Do not steal focus for apps routed to a background/special workspace.
	if win and not win.floating and win.workspace and workspace
		and win.workspace.id == workspace.id and workspace.tiled_layout == NAME then
		pending_open = win
		queue_refresh()
	end
end)
hl.on("window.active", queue_refresh)
hl.on("workspace.active", queue_refresh)
hl.on("workspace.special_active", queue_refresh)
hl.on("window.fullscreen", queue_refresh)
hl.on("workspace.removed", function(workspace)
	-- The Lua wrapper may survive the removed workspace; its id is then nil.
	local id = workspace and workspace.id
	if id ~= nil then
		rows[id] = nil
	end
end)

-- Used for shared directional bindings: other layouts keep their defaults.
function M.direction(action, direction)
	return function()
		local workspace = active_workspace()
		local active = hl.get_active_window()
		if workspace and workspace.tiled_layout == NAME and active and not active.floating then
			hl.dispatch(hl.dsp.layout(action .. " " .. direction))
		elseif action == "focus" then
			hl.dispatch(hl.dsp.focus({ direction = direction }))
		else
			hl.dispatch(hl.dsp.window.move({ direction = direction }))
		end
	end
end

return M
