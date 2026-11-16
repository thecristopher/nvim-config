-- The character of the day's region speaks up when something happens: tests, CI, a push, a boss,
-- a commit, a PR, a new region, the first nvim of the day, a merge cleared and waking from rest.
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

-- the day the character last said good morning, so the greeting comes once a day
local MORNING_FILE = vim.fn.stdpath("state") .. "/eldentree_morning"
-- after the title screen and the HUD have had their moment
local MORNING_DELAY_MS = 2500

local function greet_once_a_day()
  local today = os.date("%Y-%m-%d")
  local ok, lines = pcall(vim.fn.readfile, MORNING_FILE, "", 1)
  if not actions.morning_due(ok and lines[1] or nil, today) then
    return
  end
  require("core.utils").write_state(MORNING_FILE, { today })
  M.say("morning")
end

---Greets you on the first nvim of the day, in the voice of the day's character.
function M.setup()
  vim.api.nvim_create_autocmd("UIEnter", {
    group = vim.api.nvim_create_augroup("eldentree_voice", { clear = true }),
    once = true,
    callback = function()
      vim.defer_fn(greet_once_a_day, MORNING_DELAY_MS)
    end,
  })
end

return M
