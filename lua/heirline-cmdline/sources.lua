local config = require("heirline-cmdline.config").config

local M = {}

---@param cmd_text string
---@return HierlineCmdlineCompletionItem[],number
function M.get_cmp(cmd_text)
	for _, i in pairs(vim.fn.range(#config.source, 1, -1)) do
		for _, s in pairs(config.source[i].patterns) do
			local ok = vim.regex(s):match_str(cmd_text)
			if ok then
				local items, len
				items, len = config.source[i].provider(cmd_text)
				return items, len
			end
		end
	end
	return {}, 1
end

return M
