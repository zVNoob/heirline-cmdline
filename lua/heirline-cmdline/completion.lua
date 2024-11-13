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

local mapped = false

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

local function set_map_confirm()
	local len = _cmd_text:find(" [^ ]*$")
	if len == nil then
		len = 0
	else
		len = len + 1
	end
	if #_cmd_text - len == #vim.api.nvim_buf_get_lines(buffer, choice - 1, choice, false)[1] - 1 then
		if mapped then
			vim.keymap.del("c", config.keymap.confirm)
			vim.keymap.del("c", config.keymap.force)
			mapped = false
		end
	else
		if not mapped then
			vim.keymap.set("c", config.keymap.confirm, confirm)
			vim.keymap.set("c", config.keymap.force, "<CR>")
			mapped = true
		end
	end
end

local function move_down()
	if menu ~= -1 then
		local len = #vim.api.nvim_buf_get_text(buffer, 0, 0, -1, 0, {})
		if choice < len then
			choice = choice + 1
		else
			choice = 1
		end
		vim.api.nvim_win_set_cursor(menu, { choice, 0 })
		set_map_confirm()
	end
end

local function move_up()
	if menu ~= -1 then
		if choice > 1 then
			choice = choice - 1
		else
			choice = math.max(#vim.api.nvim_buf_get_text(buffer, 0, 0, -1, 0, {}), 1)
		end
		vim.api.nvim_win_set_cursor(menu, { choice, 0 })
		set_map_confirm()
	end
end

local function map_key()
	vim.keymap.set("c", config.keymap.next, move_down)
	vim.keymap.set("c", config.keymap.prev, move_up)
end

map_key()

---comment
---@param win_config vim.api.keyset.win_config
---@param cmd_text string
function M.show(win_config, cmd_text)
	_cmd_text = cmd_text

	local res = vim.tbl_map(function(i)
		return i.text
	end, source.get_cmp(cmd_text))

	if menu ~= -1 then
		vim.api.nvim_win_close(menu, true)
		menu = -1
	end

	if buffer ~= -1 then
		vim.api.nvim_buf_delete(buffer, { force = true })
	end
	buffer = vim.api.nvim_create_buf(false, true)

	vim.api.nvim_buf_set_lines(buffer, 0, #res, false, res)
	old_win_config = vim.deepcopy(win_config)
	old_win_config.row = win_config.row - 1
	old_win_config.height = math.min(config.max_item, #res, old_win_config.row)
	local len = cmd_text:find(" [^ ]*$")
	if len == nil then
		len = 0
	else
		len = len - 1
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
	set_map_confirm()
	if #res ~= 0 then
		menu = vim.api.nvim_open_win(buffer, false, old_win_config)
		vim.api.nvim_win_set_cursor(menu, { 1, 0 })
		vim.api.nvim_set_option_value(
			"winhighlight",
			"NormalNC:StatusLine,Search:,IncSearch:",
			{ scope = "local", win = menu }
		)
		vim.api.nvim_set_option_value("cursorline", true, { scope = "local", win = menu })
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
