--- @class HierlineCmdlineCompletionItem
--- @field text string
--- @field symbol? string
--- @field presymbol? string

--- @alias HierlineCmdlineSourceProvider fun(cmd_text: string, partial?: string, index?: number): HierlineCmdlineCompletionItem[],any?

--- @type HierlineCmdlineSourceProvider
local function CmdlineDefaultProvider(cmd_text)
  cmd_text = cmd_text:sub(2):gsub('\\', '\\\\')
  local res = vim.tbl_map(function(i)
    return { text = i }
  end, vim.fn.getcompletion(cmd_text, 'cmdline'))
  vim.notify(vim.inspect(res))
  return res
end

--- @class HierlineCmdlineSource
--- @field patterns string[]
--- @field provider HierlineCmdlineSourceProvider
--- @field no_cache? boolean

--- @class HierlineCmdlineConfig
--- @field placeholder_char string
--- @field max_item number
--- @field source HierlineCmdlineSource[]
local M = {
  max_item = 7,
  placeholder_char = '￼',
  source = {
    {
      patterns = { '.*' },
      provider = CmdlineDefaultProvider,
    },
  },
}

---@param input HierlineCmdlineConfig
function M.config(input)
  M = vim.tbl_extend('force', M, input)
  M.source = vim.tbl_map(function(item)
    return vim.tbl_extend('force', { no_cache = false }, item)
  end, M.source)
end

return M