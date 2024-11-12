local conditions = require("heirline.conditions")
local utils = require("heirline.utils")

local M = {}

--- @param config? HierlineCmdlineConfig
--- @return StatusLine
function M.setup(config)
	--- @diagnostic disable
	local cmdline = require("heirline-cmdline.cmdline")
	local completion = require("heirline-cmdline.completion")
	---@diagnostic enable

	local plugin_config = require("heirline-cmdline.config")
	if config then
		plugin_config.config(config)
	end
	return {
		provider = function()
			return plugin_config.placeholder_char
		end,
		hl = function()
			if conditions.is_active() then
				return { fg = utils.get_highlight("StatusLine").bg, bg = utils.get_highlight("StatusLine").bg }
			else
				return { fg = utils.get_highlight("StatusLineNC").bg, bg = utils.get_highlight("StatusLineNC").bg }
			end
		end,
	}
end

return M
