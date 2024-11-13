local config = require("heirline-cmdline.config").config
local completion = require("heirline-cmdline.completion")

local cmdline = vim.api.nvim_create_namespace("heirline_cmdline")
local M = {}
local buffer = vim.api.nvim_create_buf(false, true)

local cmd_text = ""

---@return string
function M.cmd_text()
	return cmd_text
end

--- @param ft string
function M.set_ft(ft)
	vim.api.nvim_set_option_value("filetype", ft, { buf = buffer })
end

--- @type vim.api.keyset.win_config
local win_config = {
	focusable = true,
	style = "minimal",
	border = "none",
	relative = "win",
	height = 1,
	anchor = "SW",
	-- wrap = false,
	-- foldenable = false,
	-- col = 50,
	-- row = 59,
	-- width = 50,
}

local window = -1
local cur_win = -1

function M.cur_win()
	return cur_win
end

--vim.opt_global.inccommand = "nosplit"

-- fake cursor
vim.api.nvim_set_hl(0, "HIDDEN", { blend = 100, nocombine = true })
vim.opt_global.guicursor:append({ "c:HIDDEN", "ci:HIDDEN", "cr:HIDDEN" })
local cur_pos = 0
local cur_id = -1

local function set_size()
	local width = 0
	local width_start = 1
	local row_offset = 0
	if vim.o.laststatus == 3 then
		-- global statusline
		win_config.relative = "editor"
		win_config.row = vim.o.lines - vim.o.cmdheight
		width = vim.o.columns
		win_config.win = nil
	else
		win_config.relative = "win"
		win_config.win = cur_win
		win_config.row = vim.api.nvim_win_get_height(cur_win) + 1
		width_start = vim.api.nvim_win_get_position(cur_win)[2] + 1
		row_offset = vim.api.nvim_win_get_position(cur_win)[1]
		width = width_start + vim.api.nvim_win_get_width(cur_win)
		win_config.width = width - width_start
		if vim.o.inccommand == "split" and vim.fn.getcmdline():find("s/") then
			-- HACK: move cmdline to the right location
			if win_config.row + row_offset == vim.o.lines - vim.o.cmdheight then
				win_config.row = win_config.row - vim.o.cmdwinheight - 1
			end
		end
	end

	local encountered = false
	for _, i in pairs(vim.fn.range(width_start, width)) do
		local ch = vim.fn.nr2char(vim.fn.screenchar(win_config.row + row_offset, i))
		if ch == config.placeholder_char then
			if not encountered then
				win_config.col = i - width_start + 1
				encountered = true
			else
				win_config.width = i - win_config.col - width_start
				break
			end
		end
	end
end

local function is_valid()
	local width_start = 1
	local row_offset = 0
	if vim.o.laststatus ~= 3 then
		while true do
			local ok, res = pcall(vim.api.nvim_win_get_position, cur_win)
			if ok then
				width_start = res[2] + 1
				row_offset = res[1]
				break
			else
				cur_win = vim.api.nvim_get_current_win()
			end
		end
	end
	return vim.fn.nr2char(vim.fn.screenchar(win_config.row + row_offset, width_start + win_config.col - 1))
			== config.placeholder_char
		and vim.fn.nr2char(
				vim.fn.screenchar(win_config.row + row_offset, width_start + win_config.col + win_config.width)
			)
			== config.placeholder_char
end

local function render(firstc, content)
	cmd_text = firstc .. content[1][2]
	vim.api.nvim_buf_set_lines(buffer, 0, 1, false, { cmd_text .. " " })
	if cur_id == -1 then
		cur_id = vim.api.nvim_buf_set_extmark(
			buffer,
			cmdline,
			0,
			cur_pos + 1,
			{ end_row = 0, end_col = cur_pos + 2, hl_group = "Cursor" }
		)
	else
		vim.api.nvim_buf_set_extmark(
			buffer,
			cmdline,
			0,
			cur_pos + 1,
			{ id = cur_id, end_row = 0, end_col = cur_pos + 2, hl_group = "Cursor" }
		)
	end
	vim.cmd("redraw!")
	if cur_win == -1 then
		cur_win = vim.api.nvim_get_current_win()
		set_size()
	end
	if
		(not is_valid() or window == -1)
		and not (
			vim.api.nvim_get_mode().mode == "c"
			and vim.fn.getcmdline():find("s/")
			and vim.fn.has("nvim-0.11") ~= 1
		)
	then
		if window ~= -1 then
			vim.api.nvim_win_close(window, true)
		end
		if vim.api.nvim_win_get_config(vim.api.nvim_get_current_win()).relative == "" then
			cur_win = vim.api.nvim_get_current_win()
		end
		set_size()
		window = vim.api.nvim_open_win(buffer, false, win_config)
		vim.api.nvim_set_option_value(
			"winhighlight",
			"Normal:StatusLine,Search:StatusLine,IncSearch:StatusLine",
			{ scope = "local", win = window }
		)
		vim.api.nvim_set_option_value("wrap", false, { scope = "local", win = window })
	end
	vim.api.nvim_win_set_cursor(window, { 1, cur_pos + 1 })

	vim.schedule(function()
		completion.show(win_config, cmd_text)
	end)
end

local function ui_handler(event, ...)
	if event == "cmdline_show" then
		local content, pos, firstc, prompt, indent, level = ...
		cur_pos = pos
		local rendered = false
		if (firstc .. content[1][2]) ~= cmd_text then
			rendered = true
			render(firstc, content)
		end
		if not rendered then
			vim.cmd("redrawstatus")
			if not is_valid() then
				render(firstc, content)
			end
		end
		if vim.api.nvim_get_mode().mode == "c" and vim.fn.getcmdline():find("s/") then
			-- HACK: this will trigger redraw during substitue
			vim.cmd("redraw!")
			-- completion.show(win_config, cmd_text)
			--- vim.schedule_wrap(ui_handler)(event, ...)
		end
	end
	if event == "cmdline_pos" then
		local pos = ...
		if pos ~= nil then
			cur_pos = pos
			vim.api.nvim_buf_set_extmark(
				buffer,
				cmdline,
				0,
				cur_pos + 1,
				{ id = cur_id, end_row = 0, end_col = cur_pos + 2, hl_group = "Cursor" }
			)
			vim.api.nvim_win_set_cursor(window, { 1, cur_pos + 1 })
			--vim.cmd.redraw()
		end
	end

	if event == "cmdline_hide" then
		cmd_text = ""
		vim.api.nvim_win_close(window, true)
		completion.hide()
		window = -1
		--vim.cmd.redraw()
	end
	vim.cmd("redraw")
end

vim.ui_attach(cmdline, { ext_cmdline = true }, ui_handler)

return M
