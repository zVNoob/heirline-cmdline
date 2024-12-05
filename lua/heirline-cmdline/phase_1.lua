local config = require("heirline-cmdline.config").config
-- Phase 1: Determine the size of potential cmdline

local M = {
	phase_2_ignore_react = false,
}

local current_win = -1
---@type vim.api.keyset.win_config?
local current_win_config = nil
local is_using_cmdline = false
local trigger_char = ""

--Optimization

---@return boolean
local function check_unchanged()
	if current_win_config == nil then
		return false
	end
	if current_win ~= current_win_config.win then
		return false
	end
	local row_offset = 1
	local width_start = 0
	if vim.o.laststatus ~= 3 then
		width_start = vim.api.nvim_win_get_position(current_win)[2] + 1
		row_offset = vim.api.nvim_win_get_position(current_win)[1]
	end
	return vim.fn.nr2char(
		vim.fn.screenchar(current_win_config.row + row_offset, width_start + current_win_config.col - 1)
	) == config.placeholder_char and vim.fn.nr2char(
		vim.fn.screenchar(
			current_win_config.row + row_offset,
			width_start + current_win_config.col + current_win_config.width
		)
	) == config.placeholder_char
end

-- Laststatus cache

local old_laststatus = -1
local function set_laststatus(set)
	if set then
		if vim.o.laststatus ~= 3 then
			old_laststatus = vim.o.laststatus
			vim.o.laststatus = 3
		end
	else
		if old_laststatus ~= -1 then
			vim.o.laststatus = old_laststatus
			old_laststatus = -1
		end
	end
	vim.cmd("redrawstatus")
end

local function set_laststatus_force(set)
	-- Tell phase 2 not react
	M.phase_2_ignore_react = true
	-- Cache and clean cmdline
	local cmdline_cache = trigger_char .. vim.fn.getcmdline()
	-- Temporarily disable cmdline
	local buffer = ""
	for _ in pairs(vim.fn.range(#cmdline_cache)) do
		buffer = buffer .. "<BS>"
	end
	local buffer2 = vim.api.nvim_replace_termcodes(buffer, true, false, true)
	vim.api.nvim_feedkeys(buffer2, "n", false)
	set_laststatus(set)
	-- re-enable cmdline
	vim.api.nvim_feedkeys(cmdline_cache:sub(0, #cmdline_cache - 2), "n", false)
	-- Re-trigger phase 2
	M.phase_2_ignore_react = false
	vim.api.nvim_feedkeys(cmdline_cache:sub(#cmdline_cache), "n", false)
end
-- Building
---@param can_set_laststatus boolean
---@return vim.api.keyset.win_config
local function build_config(can_set_laststatus)
	---@type vim.api.keyset.win_config
	local result = {
		style = "minimal",
		border = "none",
		relative = "win",
		anchor = "SW",
		height = 1,
		width = 0,
		col = 1,
	}
	local width_start = 1
	local row_offset = 0
	local width = 0
	if vim.o.laststatus == 3 then
		-- global statusline
		result.relative = "editor"
		result.row = vim.o.lines - vim.o.cmdheight
		width = vim.o.columns
	else
		result.win = current_win
		result.row = vim.api.nvim_win_get_height(result.win) + 1
		width_start = vim.api.nvim_win_get_position(result.win)[2] + 1
		row_offset = vim.api.nvim_win_get_position(result.win)[1]
		width = width_start + vim.api.nvim_win_get_width(result.win)
	end
	local encountered = false
	for _, i in pairs(vim.fn.range(width_start, width)) do
		local ch = vim.fn.nr2char(vim.fn.screenchar(result.row + row_offset, i))
		if ch == config.placeholder_char then
			if not encountered then
				result.col = i - width_start + 1
				encountered = true
			else
				result.width = i - result.col - width_start
				break
			end
		end
	end
	if result.width < config.min_width then
		if vim.o.laststatus ~= 3 then
			if can_set_laststatus then
				set_laststatus(true)
				return build_config(true)
			else
				set_laststatus_force(true)
				return build_config(true)
			end
		else
		end
	end
	return result
end

---@return vim.api.keyset.win_config,boolean
function M.build_win_config()
	local new_win_config = build_config(not is_using_cmdline)
	local modified = vim.inspect(new_win_config) ~= vim.inspect(current_win_config)
	if check_unchanged() or vim.fn.getcmdline():find("s/") or not modified then
		---@diagnostic disable-next-line
		return current_win_config, false
	end
	current_win_config = new_win_config
	return current_win_config, true
end

local function phase_1_handler(initial_character)
	trigger_char = initial_character
	-- prepare initial config
	current_win = vim.api.nvim_get_current_win()
	is_using_cmdline = false
	M.build_win_config()
	-- trigger phase 2
	M.detach()
	is_using_cmdline = true
	vim.api.nvim_input(initial_character)
end

-- Workaround function

local function phase_1_colon()
	phase_1_handler(":")
end

local function phase_1_slash()
	phase_1_handler("/")
end

local function phase_1_question()
	phase_1_handler("?")
end

-- Attach/detach function

local attached = false

function M.attach()
	if not attached then
		vim.keymap.set({ "n", "v" }, ":", phase_1_colon)
		vim.keymap.set({ "n", "v" }, "/", phase_1_slash)
		vim.keymap.set({ "n", "v" }, "?", phase_1_question)

		set_laststatus(false)

		is_using_cmdline = false
		attached = true
	end
end

function M.detach()
	if attached then
		vim.keymap.del({ "n", "v" }, ":")
		vim.keymap.del({ "n", "v" }, "/")
		vim.keymap.del({ "n", "v" }, "?")

		attached = false
	end
end

return M
