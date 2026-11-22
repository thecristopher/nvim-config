-- The character of the day's region speaks up when something happens: tests, CI, a push, a boss,
-- a commit, a PR, a new region, the first nvim of the day, a merge cleared and waking from rest.
-- Lines live in each lore's voices.lua, a region without lines stays quiet. A region whose `spoken`
-- names clips says them out loud instead, and only then speaks at the moments in actions.SPOKEN.
-- vim.g.eldentree_voice = false silences them.
local actions = require("core.voice.actions")

local M = {}

-- the line said last, so the same one never comes twice in a row
local last = nil

---The region's character's line for a moment, filled in, or nil when they have nothing to say.
---@param moment string like trial_passed, ci_failed, pushed or boss_felled
---@param vars table<string, string>|nil values for the line's holes, like branch or boss
---@return string|nil line
---@return string|nil character who says it
function M.line(moment, vars)
  if vim.g.eldentree_voice == false then
    return nil
  end
  local region = require("core.themes").current()
  local voices = require("core.franchise").current().voices
  local line = actions.line(voices, region.name, moment, math.random(), last)
  if not line then
    return nil
  end
  last = line
  return actions.fill(line, vars), region.character
end

-- the clip played last, so the same one never comes twice in a row
local last_clip = nil

-- plays the region's clip for a moment and returns what it says, nil when it has none or no
-- sound can play right now
local function speak(region, moment)
  local voices = require("core.franchise").current().voices
  local clip, line = actions.clip(voices, region.name, moment, math.random(), last_clip)
  if not clip then
    return nil
  end
  local sound = require("core.sound")
  local dir = sound.folder() .. "/voices/" .. region.name
  local ok, files = pcall(vim.fn.readdir, dir)
  local file = ok and actions.clip_file(files, clip, require("core.sound.actions").EXTENSIONS)
  if not file or not sound.speak(dir .. "/" .. file) then
    return nil
  end
  last_clip = clip
  return line
end

---Has the region's character say their line for a moment out loud when the region has a clip
---for it, and returns the words without showing them, for callers that place them themselves.
---@param moment string like trial_passed, ci_failed, pushed or boss_felled
---@param vars table<string, string>|nil values for the line's holes, like branch or boss
---@return string|nil line what they said or would say, nil when they have nothing
---@return string|nil character who says it
---@return boolean spoke whether the character said it out loud
function M.speak(moment, vars)
  if vim.g.eldentree_voice == false then
    return nil, nil, false
  end
  local region = require("core.themes").current()
  local spoken = speak(region, moment)
  if spoken then
    return actions.fill(spoken, vars), region.character, true
  end
  local line, character = M.line(moment, vars)
  return line, character, false
end

---Has the region's character say their line for a moment: out loud when the region has a clip
---for it (sounds/<franchise>/voices/<region>/), written otherwise, both as a notification under
---their name. A moment only heard out loud stays quiet without its clip.
---@param moment string like trial_passed, ci_failed, pushed or boss_felled
---@param vars table<string, string>|nil values for the line's holes, like branch or boss
---@param opts? { quiet?: boolean } quiet leaves the spoken words off screen, for moments that
---already show something of their own (the coach's stage, the rest)
---@return boolean spoke whether the character said it out loud
function M.say(moment, vars, opts)
  local line, character, spoke = M.speak(moment, vars)
  if line and not (spoke and opts and opts.quiet) then
    vim.notify(line, vim.log.levels.INFO, { title = character })
  end
  return spoke
end

-- the day the character last said good morning, so the greeting comes once a day
local MORNING_FILE = vim.fn.stdpath("state") .. "/eldentree_morning"
-- after the title screen, the HUD and the title's spoken line have had their moment
local MORNING_DELAY_MS = 4000

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
