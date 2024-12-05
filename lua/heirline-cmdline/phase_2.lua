local cmdline = vim.api.nvim_create_namespace("heirline_cmdline")
local phase_1 = require("heirline-cmdline.phase_1")
local completion = require("heirline-cmdline.completion")
-- Buffer
local buffer = vim.api.nvim_create_buf(false, true)
-- Window (forward declaration)
local window_id = -1

-- Cursor
local cursor_id = -1
---@param pos number
local function set_cursor_pos(pos)
	if cursor_id == -1 then
		cursor_id = vim.api.nvim_buf_set_extmark(
			buffer,
			cmdline,
			0,
			pos + 1,
			{ end_row = 0, end_col = pos + 2, hl_group = "Cursor" }
		)
	else
		vim.api.nvim_buf_set_extmark(
			buffer,
			cmdline,
			0,
			pos + 1,
			{ id = cursor_id, end_row = 0, end_col = pos + 2, hl_group = "Cursor" }
		)
	end
	if window_id ~= -1 then
		vim.api.nvim_win_set_cursor(window_id, { 1, pos + 1 })
	end
end

-- Window
vim.api.nvim_set_hl(0, "HIDDEN", { blend = 100, nocombine = true })
vim.opt_global.guicursor:append({ "c:HIDDEN", "ci:HIDDEN", "cr:HIDDEN" })

---@param cmd_text string
local function render(cmd_text)
	vim.api.nvim_buf_set_lines(buffer, 0, 1, false, { cmd_text .. " " })
	if cmd_text:find("s/") == nil then
		if window_id ~= -1 then
			vim.api.nvim_win_close(window_id, true)
		end
		local win_config, state_modified = phase_1.build_win_config()
		window_id = vim.api.nvim_open_win(buffer, false, win_config)
		vim.api.nvim_set_option_value(
			"winhighlight",
			"Normal:StatusLine,Search:StatusLine,IncSearch:StatusLine",
			{ scope = "local", win = window_id }
		)
		vim.api.nvim_set_option_value("wrap", false, { scope = "local", win = window_id })
		completion.show(win_config, cmd_text)
	end
end

local function phase_2_handler(event, ...)
	if not phase_1.phase_2_ignore_react then
		if event == "cmdline_show" then
			local content, pos, firstc, prompt, indent, level = ...
			render(firstc .. content[1][2])
			set_cursor_pos(pos)
		end
		if event == "cmdline_pos" then
			local pos = ...
			set_cursor_pos(pos)
		end
		if event == "cmdline_hide" then
			vim.api.nvim_win_close(window_id, true)
			completion.hide()
			window_id = -1
			phase_1.attach()
		end
		vim.cmd.redraw()
	end
end

vim.ui_attach(cmdline, { ext_cmdline = true }, phase_2_handler)
