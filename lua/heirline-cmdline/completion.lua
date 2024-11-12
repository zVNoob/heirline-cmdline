local config = require("heirline-cmdline.config").config
local source = require("heirline-cmdline.sources")

local menu = -1

local M = {}

--- @type vim.api.keyset.win_config
local old_win_config = {
	focusable = true,
	style = "minimal",
	border = "none",
	relative = "win",
	height = 1,
	anchor = "SW",
	col = 50,
	row = 59,
	width = 50,
}

local buffer = -1

local width = -1
local col = -1

vim.o.wildchar = -1

local choice = 1
local _cmd_text = ""

local function move_down()
	if buffer ~= -1 then
		local len = #vim.api.nvim_buf_get_text(buffer, 0, 0, -1, 0, {})
		if choice < len then
			choice = choice + 1
			vim.api.nvim_win_set_cursor(menu, { choice, 0 })
		end
	end
end

local function move_up()
	if buffer ~= -1 then
		if choice > 1 then
			choice = choice - 1
			vim.api.nvim_win_set_cursor(menu, { choice, 0 })
		end
	end
end

local mapped = false

local function unmap_confirm()
	if mapped then
		vim.keymap.del("c", "<CR>")
		vim.keymap.del("c", "<M-CR>")
		mapped = false
	end
end

local function confirm()
	local len = _cmd_text:find(" [^ ]*$")
	if len == nil then
		len = 0
	else
		len = len - 1
	end
	local text = vim.api.nvim_buf_get_lines(buffer, choice - 1, choice, false)[1]
	vim.api.nvim_feedkeys(text:sub(#_cmd_text - len), "c", false)
end

local function map_key()
	vim.keymap.set("c", "<Tab>", move_down)
	vim.keymap.set("c", "<S-Tab>", move_up)
end

local function map_confirm()
	if not mapped then
		vim.keymap.set("c", "<CR>", confirm)
		vim.keymap.set("c", "<M-CR>", "<CR>")
		mapped = true
	end
end

map_key()

---comment
---@param win_config vim.api.keyset.win_config
---@param cmd_text string
function M.show(win_config, cmd_text)
	-- local res = source.get_cmp(cmd_text, 1, config.max_item, false)
	-- vim.notify(vim.inspect(res))
	-- res = vim.tbl_map(function(i)
	--   return i.text
	-- end, res)
	_cmd_text = cmd_text
	if menu ~= -1 then
		vim.api.nvim_win_close(menu, true)
		menu = -1
	end

	if buffer ~= -1 then
		vim.api.nvim_buf_delete(buffer, { force = true })
	end
	buffer = vim.api.nvim_create_buf(false, true)
	cmd_text = cmd_text:sub(2):gsub("\\", "\\\\")
	local res = vim.fn.getcompletion(cmd_text, "cmdline")
	if #res == 0 then
		unmap_confirm()
	end
	vim.api.nvim_buf_set_lines(buffer, 0, #res, false, res)
	old_win_config = vim.deepcopy(win_config)
	old_win_config.row = win_config.row - 1
	old_win_config.height = math.min(config.max_item, #res, old_win_config.row)
	local len = cmd_text:find(" [^ ]*$")
	if len == nil then
		len = 0
	end
	old_win_config.col = old_win_config.col + 1 + len
	if old_win_config.col ~= col then
		width = -1
		col = old_win_config.col
	end
	for _, i in pairs(res) do
		width = math.max(width, #i)
	end
	old_win_config.width = width
	choice = 1
	if cmd_text:sub(math.max(1, len)):find(vim.api.nvim_buf_get_lines(buffer, choice - 1, choice, false)[1]) then
		unmap_confirm()
	else
		map_confirm()
	end
	if #res ~= 0 then
		menu = vim.api.nvim_open_win(buffer, false, old_win_config)
		vim.api.nvim_win_set_cursor(menu, { 1, 0 })
		vim.api.nvim_set_option_value("winhighlight", "NormalNC:StatusLine", { win = menu })
		vim.api.nvim_set_option_value("cursorline", true, { win = menu })
	end
end

function M.hide()
	if menu ~= -1 then
		vim.api.nvim_win_close(menu, true)
	end
	menu = -1
	col = -1
end

return M
