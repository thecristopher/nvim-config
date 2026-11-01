-- The character of the day's region speaks up when something happens: tests, CI, a push, a boss.
-- Lines live in each lore's voices.lua, a region without lines stays quiet.
-- vim.g.eldentree_voice = false silences them.
local actions = require("core.voice.actions")

local M = {}

-- the line said last, so the same one never comes twice in a row
local last = nil

---Has the region's character say their line for a moment, as a notification under their name.
---@param moment string like trial_passed, ci_failed, pushed or boss_felled
---@param vars table<string, string>|nil values for the line's holes, like branch or boss
function M.say(moment, vars)
  if vim.g.eldentree_voice == false then
    return
  end
  local region = require("core.themes").current()
  local voices = require("core.franchise").current().voices
  local line = actions.line(voices, region.name, moment, math.random(), last)
  if not line then
    return
  end
  last = line
  vim.notify(actions.fill(line, vars), vim.log.levels.INFO, { title = region.character })
end

return M
