local config = require("heirline-cmdline.config")
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
	-- col = 50,
	-- row = 59,
	-- width = 50,
}
local window = -1
local cur_win = -1

local set_size = function()
	local width = 0
	local width_start = 1
	local row_offset = 0
	if vim.o.laststatus == 3 then
		-- global statusline
		win_config.relative = "editor"
		win_config.row = vim.o.lines - vim.o.cmdheight
		width = vim.o.columns
	else
		win_config.relative = "win"
		win_config.row = vim.api.nvim_win_get_height(cur_win) + 1
		width_start = vim.api.nvim_win_get_position(cur_win)[2] + 1
		row_offset = vim.api.nvim_win_get_position(cur_win)[1]
		width = width_start + vim.api.nvim_win_get_width(cur_win)
		win_config.width = width - width_start
	end
	local encountered = false
	for _, i in pairs(vim.fn.range(width_start, width)) do
		if i < width_start then
			vim.notify(tostring(i))
		end
		local ch = vim.fn.nr2char(vim.fn.screenchar(win_config.row + row_offset, i))
		if ch == config.placeholder_char then
			win_config.col = i - width_start + 1
			encountered = true
		else
			if ch ~= " " then
				if encountered then
					win_config.width = i - win_config.col - width_start
					break
				end
			end
		end
	end
end

local function ui_handler(event, ...)
	if event == "cmdline_show" then
		local content, pos, firstc, prompt, indent, level = ...
		local rendered = false
		if (firstc .. content[1][2]) ~= cmd_text then
			rendered = true
			cmd_text = firstc .. content[1][2]
			vim.api.nvim_buf_set_lines(buffer, 0, 1, false, { cmd_text .. "█" })

			vim.cmd("redraw!")
			if window ~= -1 then
				vim.api.nvim_win_close(window, true)
			end
			cur_win = vim.api.nvim_get_current_win()
			set_size()
			window = vim.api.nvim_open_win(buffer, false, win_config)
			vim.api.nvim_set_option_value("winhighlight", "Normal:StatusLine", { scope = "local", win = window })
			completion.show(win_config, cmd_text)
		end
		vim.cmd.redraw()
		-- if not rendered then
		--   local width = 0
		--   local width_start = 1
		--   local row_offset = 0
		--   if vim.o.laststatus == 3 then
		--     -- global statusline
		--     width = vim.o.columns
		--   else
		--     width_start = vim.api.nvim_win_get_position(cur_win)[2] + 1
		--     row_offset = vim.api.nvim_win_get_position(cur_win)[1]
		--   end
		--   if vim.fn.nr2char(vim.fn.screenchar(win_config.row + row_offset, width_start + win_config.col)) ~= config.placeholder_char then
		--     ui_handler(event, ...)
		--   end
		-- end
	end

	if event == "cmdline_hide" then
		cmd_text = ""
		vim.api.nvim_win_close(window, true)
		completion.hide()
		window = -1
	end
end

vim.ui_attach(cmdline, { ext_cmdline = true }, ui_handler)

return M
