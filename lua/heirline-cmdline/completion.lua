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

---@type HierlineCmdlineCompletionItem[]
local cmp_items = {}
local choice = 1
local _cmd_text = ""

local mapped = false

local function confirm()
	local len = _cmd_text:find(" [^ ]*$")
	if len == nil then
		len = 1
	end
	local text = cmp_items[choice].text
	local backspace = ""
	local i = #_cmd_text - len
	while i > 0 do
		backspace = backspace .. vim.api.nvim_replace_termcodes("<bs>", false, true, true)
		i = i - 1
	end
	vim.api.nvim_feedkeys(backspace .. text, "c", false)
end

local len = 1

local function set_map_confirm()
	local text = ""
	if cmp_items[choice] then
		text = cmp_items[choice].text
	end
	if #_cmd_text - len >= #text then
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
		local item_len = #cmp_items
		if choice < item_len then
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
			choice = math.max(#cmp_items, 1)
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
	cmp_items, len = source.get_cmp(cmd_text)
	local res = vim.tbl_map(function(i)
		return i.text
	end, cmp_items)

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
	old_win_config.col = old_win_config.col + len
	if old_win_config.col ~= col then
		width = -1
		col = old_win_config.col
	end
	for _, i in pairs(res) do
		width = math.max(width, #i)
	end
	old_win_config.width = width
	if choice > #cmp_items then
		choice = math.max(#cmp_items, 1)
	end
	set_map_confirm()
	if #cmp_items ~= 0 then
		menu = vim.api.nvim_open_win(buffer, false, old_win_config)
		vim.api.nvim_win_set_cursor(menu, { choice, 0 })
		vim.api.nvim_set_option_value(
			"winhighlight",
			"NormalNC:StatusLine,Search:StatusLine,IncSearch:StatusLine,Substitute:StatusLine",
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
