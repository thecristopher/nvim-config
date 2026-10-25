-- Picks the franchise the whole config speaks: a new one every day, pinned with
-- vim.g.eldentree_franchise, or switched with :Franchise until midnight.
local actions = require("core.franchise.actions")

local M = {}

local state_file = vim.fn.stdpath("state") .. "/eldentree_franchise"
local active

local function today()
  return os.date("%Y-%m-%d")
end

local function read_choice()
  local ok, lines = pcall(vim.fn.readfile, state_file, "", 1)
  return ok and actions.choice_for(lines[1], today()) or nil
end

--- Returns the name of the franchise in use right now.
---@return string
function M.name()
  if vim.g.eldentree_franchise then return actions.resolve(vim.g.eldentree_franchise) end
  active = active or read_choice() or actions.of_the_day(os.date("*t"))
  return active
end

--- Returns the lore of the franchise in use: regions, bosses, weather, banners and words.
---@return table
function M.current()
  return actions.lore(M.name())
end

--- Returns which version of a mechanic the franchise plays, like "door" for travel.
---@param name string mechanic name: travel, boss, status, rest or ranking
---@return any
function M.mechanic(name)
  return M.current().mechanics[name]
end

--- Switches franchise for the rest of the day and repaints the editor in it.
---@param name string franchise name
function M.switch(name)
  if vim.g.eldentree_franchise then
    return vim.notify("vim.g.eldentree_franchise pins " .. M.current().title, vim.log.levels.WARN, { title = "Eldentree" })
  end
  active = actions.resolve(name)
  pcall(vim.fn.writefile, { actions.encode_choice(today(), active) }, state_file)
  require("core.themes").follow_franchise()
end

function M.pick()
  vim.ui.select(actions.NAMES, {
    prompt = "Choose today's franchise",
    format_item = function(name) return actions.lore(name).title end,
  }, function(name)
    if name then M.switch(name) end
  end)
end

function M.setup()
  vim.api.nvim_create_user_command("Franchise", function(cmd)
    if cmd.args == "" then return M.pick() end
    M.switch(cmd.args)
  end, {
    nargs = "?",
    complete = function() return actions.NAMES end,
    desc = "Switch today's franchise",
  })
end

return M
