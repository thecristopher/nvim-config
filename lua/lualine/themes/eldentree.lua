-- lualine loads themes with dofile on every ColorScheme, so this always matches the region
local themes = require("core.themes")
return require("core.themes.actions").lualine_theme(themes.palette())
