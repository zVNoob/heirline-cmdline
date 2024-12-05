local conditions = require("heirline.conditions")
local utils = require("heirline.utils")
local phase_1 = require("heirline-cmdline.phase_1")
local phase_2 = require("heirline-cmdline.phase_2")

local M = {}

--- @param config? HierlineCmdlineConfig
--- @return StatusLine
function M.setup(config)
	local plugin_config = require("heirline-cmdline.config")
	if config then
		plugin_config.get_config(config)
	end
	phase_1.attach()
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
