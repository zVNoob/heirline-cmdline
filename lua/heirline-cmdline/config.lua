--- @class HierlineCmdlineCompletionItem
--- @field text string
--- @field symbol? string
--- @field presymbol? string

--- @alias HierlineCmdlineSourceProvider fun(cmd_text: string, partial?: string, index?: number): HierlineCmdlineCompletionItem[],any?

--- @type HierlineCmdlineSourceProvider
local function CmdlineDefaultProvider(cmd_text)
	cmd_text = cmd_text:sub(2):gsub("\\", "\\\\")
	local res = vim.tbl_map(function(i)
		return { text = i }
	end, vim.fn.getcompletion(cmd_text, "cmdline"))
	return res
end

local M = {}

--- @class HierlineCmdlineSource
--- @field patterns string[]
--- @field provider HierlineCmdlineSourceProvider
--- @field no_cache? boolean

--- @class HierlineCmdlineConfig
--- @field placeholder_char string
--- @field max_item number
--- @field source HierlineCmdlineSource[]
---
M.config = {
	max_item = 7,
	placeholder_char = "￼",
	source = {
		{
			patterns = { ".*" },
			provider = CmdlineDefaultProvider,
		},
	},
}

---@param input HierlineCmdlineConfig
function M.get_config(input)
	M.config = vim.tbl_extend("force", M.config, input)
	M.config.source = vim.tbl_map(function(item)
		return vim.tbl_extend("force", { no_cache = false }, item)
	end, M.config.source)
end

return M
