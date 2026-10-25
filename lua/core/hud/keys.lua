-- The keys every HUD offers: what each does, its icon, and the short name its slot prints.
local M = {}

local function words()
  return require("core.franchise").current().words
end

--- Returns the HUD keys: icon, key, what it does, and the short name its slot prints.
---@return table[]
function M.keys()
  return {
    {
      icon = "󰍉 ",
      key = "f",
      desc = "Find File",
      action = function()
        Snacks.picker.files()
      end,
      slot = "Files",
    },
    {
      icon = "󰊄 ",
      key = "g",
      desc = "Live Grep",
      action = function()
        Snacks.picker.grep()
      end,
      slot = "Grep",
    },
    {
      icon = "󰋚 ",
      key = "r",
      desc = "Recent Files",
      action = function()
        Snacks.picker.recent()
      end,
      slot = "Recent",
    },
    {
      icon = "󰊢 ",
      key = "p",
      desc = words().sites,
      action = function()
        require("core.repos").pick()
      end,
      slot = words().sites,
    },
    {
      icon = "󰉋 ",
      key = "e",
      desc = "Explorer",
      action = ":Neotree toggle",
      slot = "Explorer",
    },
    {
      icon = "󰝰 ",
      key = "o",
      desc = "Open Folder",
      action = function()
        require("core.repos").open_folder()
      end,
      slot = "Folder",
    },
    {
      icon = "󰝒 ",
      key = "n",
      desc = "New File",
      action = ":ene | startinsert",
      slot = "New",
    },
    {
      icon = "󰆔 ",
      key = "s",
      desc = "Restore Session",
      action = function()
        require("persistence").load()
      end,
      slot = "Session",
    },
    {
      icon = "󰏘 ",
      key = "t",
      desc = words().choose_region,
      action = function()
        require("core.themes").pick()
      end,
      slot = "Region",
    },
    {
      icon = "󰒓 ",
      key = "c",
      desc = "Config",
      action = function()
        Snacks.picker.files({ cwd = vim.fn.stdpath("config") })
      end,
      slot = "Config",
    },
    { icon = "󰒲 ", key = "L", desc = "Lazy", action = ":Lazy", slot = "Lazy" },
    { icon = "󰏗 ", key = "m", desc = "Mason", action = ":Mason", slot = "Mason" },
    { icon = "󰐥 ", key = "q", desc = "Quit", action = ":qa", slot = "Quit" },
    {
      icon = "▦ ",
      key = "a",
      desc = "Project Map",
      action = function()
        require("core.map").open()
      end,
      slot = "Map",
    },
  }
end

return M
