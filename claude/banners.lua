-- Runs core.claude_ui.banners for Claude Code: nvim -l <this repo>/claude/banners.lua
-- nvim -l skips the user config, so the repo's lua folder is added to the path by hand.
-- absolute even when run as a relative path, the installer writes it into settings.json
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
package.path = ("%s/lua/?.lua;%s/lua/?/init.lua;"):format(root, root) .. package.path
require("core.claude_ui.banners").run(root, _G.arg)
