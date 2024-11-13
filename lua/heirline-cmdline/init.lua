local conditions = require("heirline.conditions")
local utils = require("heirline.utils")

local M = {}

local cur_laststatus = -1

local function on_float()
	if vim.api.nvim_win_get_config(vim.api.nvim_get_current_win()).relative ~= "" then
		cur_laststatus = vim.o.laststatus
		vim.o.laststatus = 3
	else
		if cur_laststatus ~= -1 then
			vim.o.laststatus = cur_laststatus
			cur_laststatus = -1
		end
	end
end

vim.api.nvim_create_autocmd({ "WinEnter" }, { callback = on_float })

--- @param config? HierlineCmdlineConfig
--- @return StatusLine
function M.setup(config)
	local plugin_config = require("heirline-cmdline.config")
	if config then
		plugin_config.get_config(config)
	end
	--- @diagnostic disable
	local cmdline = require("heirline-cmdline.cmdline")
	local completion = require("heirline-cmdline.completion")
	---@diagnostic enable
	return {
		provider = function()
			-- if not conditions.is_active() then
			-- 	if vim.api.nvim_get_current_win() ~= cmdline.cur_win() then
			-- 		return ""
			-- 	end
			-- end
			return plugin_config.config.placeholder_char .. "%=" .. plugin_config.config.placeholder_char
		end,
		-- hl = function()
		-- 	if conditions.is_active() then
		-- 		return { fg = utils.get_highlight("StatusLine").bg, bg = utils.get_highlight("StatusLine").bg }
		-- 	else
		-- 		return { fg = utils.get_highlight("StatusLineNC").fg, bg = utils.get_highlight("StatusLineNC").bg }
		-- 	end
		-- end,
	}
end

return M
