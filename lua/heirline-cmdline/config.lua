--- @class HierlineCmdlineCompletionItem
--- @field text string
--- @field abbr? string
--- @field preabbr? string

--- @alias HierlineCmdlineSourceProvider fun(cmd_text: string, partial?: string, index?: number): HierlineCmdlineCompletionItem[]

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

--- @class HierlineCmdlineConfig
--- @field placeholder_char string
--- @field max_item number
--- @field source HierlineCmdlineSource[]
--- @field keymap {confirm: string, next: string, prev: string, force: string}
M.config = {
	max_item = 7,
	placeholder_char = "￼",
	source = {
		{
			patterns = { ":.*" },
			provider = CmdlineDefaultProvider,
		},
	},
	keymap = {
		confirm = "<CR>",
		next = "<Tab>",
		prev = "<S-Tab>",
		force = "<M-CR>",
	},
}

---@param input HierlineCmdlineConfig
function M.get_config(input)
	M.config = vim.tbl_extend("force", M.config, input)
end

return M
