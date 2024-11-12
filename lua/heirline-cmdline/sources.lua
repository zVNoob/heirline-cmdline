local config = require("heirline-cmdline.config")

local M = {}

---@type HierlineCmdlineCompletionItem[]
M.cache = {}

local partial = nil

---@param cmd_text string
---@param start_index number
---@param len number
---@param searching boolean
---@return HierlineCmdlineCompletionItem[]
function M.get_cmp(cmd_text, start_index, len, searching)
	if not searching then
		M.cache = {}
		partial = nil
	end

	while true do
		local in_cache = true
		for _, i in vim.fn.range(start_index, start_index + len) do
			if M.cache[i] == nil then
				in_cache = false
				break
			end
		end
		if in_cache then
			break
		end
		local result, no_cache = M.get_cmp_from_sources(cmd_text, start_index, len)
		vim.inspect(vim.inspect(result))
		M.cache = vim.tbl_extend("force", M.cache, result)
		if no_cache then
			local new_cache = {}
			for i, v in pairs(result) do
				if i >= start_index and i < start_index + len then
					new_cache[i] = v
				end
			end
			M.cache = new_cache
		end
	end
	local result = {}
	for i, c in pairs(vim.fn.range(start_index, start_index + len)) do
		result[i] = M.cache[c]
	end
	return result
end

---@param start_index number
---@param cmd_text string
---@param len number
---@return HierlineCmdlineCompletionItem[], boolean
function M.get_cmp_from_sources(cmd_text, start_index, len)
	-- Traverse from the end of the source
	for _, i in pairs(vim.fn.range(#config.source, 1, -1)) do
		for _, regex in pairs(config.source[i].patterns) do
			if cmd_text:match(regex) then
				local result
				while true do
					local current_result = {}
					current_result, partial = config.source[i].provider(cmd_text, partial, start_index)
					if partial == nil then
						result = vim.tbl_extend("force", result, current_result)
						break
					end
					if current_result == {} then
						break
					end
					result = vim.tbl_extend("force", result, current_result)
					if #result >= len then
						break
					end
					start_index = start_index + #current_result
				end
				return result, config.source[i].no_cache
			end
		end
	end
	return {}, false
end

return M
