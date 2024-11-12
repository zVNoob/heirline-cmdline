local config = require("heirline-cmdline.config").config

local M = {}

---@param cmd_text string
---@return HierlineCmdlineCompletionItem[]
function M.get_cmp(cmd_text)
	for _, i in pairs(vim.fn.range(#config.source, 1, -1)) do
		for _, s in pairs(config.source[i].patterns) do
			local ok = pcall(string.match, cmd_text, s)
			if ok then
				return config.source[i].provider(cmd_text)
			end
		end
	end
	return {}
end

return M
