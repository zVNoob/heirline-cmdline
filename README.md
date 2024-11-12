# (WIP) heirline-cmdline
Your cmdline on your [heirline](https://github.com/rebelot/heirline.nvim) statusline
## Why?
Do you find the spacious part of statusline is useless?
Do you want use that for something more meaningful?
Or, just like me, want to make the litte 'C' visible when `cmdheight=0`
## Installation
[lazy.nvim](https://github.com/folke/lazy.nvim)
```lua
return {
'rebelot/heirline.nvim',
  dependencies = {
	  ...,
	  'zVNoob/heirline-cmdline',
  },
  event = 'UiEnter',
  config = function()
    require('heirline').setup {
	    ...,
	    require('heirline-cmdline').setup({}),
	    ...,
    }
}
```
## Configuration
```lua
require('heirline-cmdline').setup({
	max_item = 7,
	placeholder_char = "￼",
})
```
## How it work
This plugin return an invisible U+FFFC (configurable) character which indicate the starting point of your potential cmdline, then do all the hack to render the remaining part properly
## TODO
- [x] cmdline
    - [ ] highlighting
    - [ ] substitute patterns
- [x] completion
	- [ ] custom provider
	- [ ] abbr, pre-abbr support
