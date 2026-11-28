-- The character of the day's region speaks up when something happens: tests, CI, a push, a boss,
-- a commit, a PR, a new region, the first nvim of the day, a merge cleared and waking from rest.
-- Lines live in each lore's voices.lua, a region without lines stays quiet. A region whose `spoken`
-- names clips says them out loud instead, and only then speaks at the moments in actions.SPOKEN.
-- vim.g.eldentree_voice = false silences them.
local actions = require("core.voice.actions")

local M = {}

-- what was said last, any way it was said, for :Voice last
local said = nil

-- the voice speaking now ({ priority, id }, nil when quiet) and the one moment waiting for it
local speaking = nil
local waiting = nil
local voices_started = 0

-- the holes every moment can fill from the clock and the project, under the moment's own
local function with_context(vars)
  local root = require("core.git").repo()
  local repo = root and vim.fn.fnamemodify(root, ":t") or nil
  return vim.tbl_extend("force", actions.context(os.date("*t"), repo), vars or {})
end

-- the written lines of a moment: the region's own, and every take of the role's script and fresh
-- ones as words, so new lines can be read when they cannot be heard. Moments only heard out loud
-- stay quiet without audio
local function written(region, moment, vars)
  local voices = require("core.franchise").current().voices
  local lines = vim.deepcopy(((voices or {})[region.name] or {})[moment] or {})
  if vim.tbl_contains(actions.MOMENTS, moment) then
    vim.list_extend(lines, require("core.voice.studio").written(region, moment, vars) or {})
  end
  return lines
end

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
  vars = with_context(vars)
  local lines = vim.tbl_map(function(line)
    return actions.fill(line, vars)
  end, written(region, moment, vars))
  lines = vim.tbl_filter(function(line)
    return not line:find("{%w+}")
  end, lines)
  local key = "written/" .. region.name .. "/" .. moment
  local line = actions.pick(lines, math.random(), require("core.voice.recent").get(key))
  if not line then
    return nil
  end
  require("core.voice.recent").note(key, line)
  return line, region.character
end

-- plays the region's clip for a moment and returns what it says, nil when it has none or no
-- sound can play right now
local function speak(region, moment, on_done)
  local voices = require("core.franchise").current().voices
  local key = "clip/" .. region.name .. "/" .. moment
  local recent = require("core.voice.recent")
  local clip, line = actions.clip(voices, region.name, moment, math.random(), recent.get(key))
  if not clip then
    return nil
  end
  local sound = require("core.sound")
  local dir = sound.folder() .. "/voices/" .. region.name
  local files = require("core.utils").list_dir(dir)
  local file = actions.clip_file(files, clip, require("core.sound.actions").EXTENSIONS)
  if not file or not sound.speak(dir .. "/" .. file, on_done) then
    return nil
  end
  recent.note(key, clip)
  return line
end

---Has the region's character say their line for a moment out loud when the region has a clip
---for it, and returns the words without showing them, for callers that place them themselves.
---@param moment string like trial_passed, ci_failed, pushed or boss_felled
---@param vars table<string, string>|nil values for the line's holes, like branch or boss
---@param on_done? fun() called once a spoken line is over (a Fish Audio take may still be on its
---way when this returns), never for a written one
---@return string|nil line what they said or would say, nil when they have nothing
---@return string|nil character who says it
---@return boolean spoke whether the character said it out loud
function M.speak(moment, vars, on_done)
  if vim.g.eldentree_voice == false then
    return nil, nil, false
  end
  local region = require("core.themes").current()
  vars = with_context(vars)
  -- a role cast with a Fish Audio voice speaks through the studio, the recorded clips stay behind it
  local performed = require("core.voice.studio").perform(region, moment, vars, on_done)
  if performed then
    return performed, region.character, true
  end
  local spoken = speak(region, moment, on_done)
  if spoken then
    return actions.fill(spoken, vars), region.character, true
  end
  local line, character = M.line(moment, vars)
  return line, character, false
end

-- keeps a spoken line's words on screen until the voice is over: the returned function takes
-- them away a moment after it, and the cap takes them away if the voice never says it ended
local function hold(hide)
  local shown_at = vim.uv.now()
  vim.defer_fn(hide, actions.SHOWN_MAX_MS)
  return function()
    vim.defer_fn(hide, actions.linger(vim.uv.now() - shown_at))
  end
end

local say_now

-- the voice is over: the moment waiting for it speaks if it still matters. A voice cut by a
-- louder one ends after that one started, so only the voice speaking now lets the queue go
local function voice_over(id)
  if not (speaking and speaking.id == id) then
    return
  end
  speaking = nil
  local next_moment = waiting
  waiting = nil
  if next_moment and actions.still_fresh(next_moment.at, vim.uv.now()) then
    vim.schedule(function()
      M.say(next_moment.moment, next_moment.vars, next_moment.opts)
    end)
  end
end

-- speaks a moment and hands back keep(hide), which holds the words until the voice is over (the
-- voice can end before speak returns, a clip that fails to decode, so keep releases at once then)
local function speaking_line(moment, vars)
  voices_started = voices_started + 1
  local id, before = voices_started, speaking
  speaking = { priority = actions.priority(moment), id = id }
  local over, release = false, nil
  local line, character, spoke = M.speak(moment, vars, function()
    over = true
    voice_over(id)
    if release then
      release()
    end
  end)
  if not spoke and speaking and speaking.id == id then
    speaking = before
  end
  local function keep(hide)
    release = hold(hide)
    if over then
      release()
    end
  end
  return line, character, spoke, keep
end

-- says a moment now: out loud with its words held until the voice ends, or written
function say_now(moment, vars, opts)
  local quiet = opts and opts.quiet
  local line, character, spoke, keep = speaking_line(moment, vars)
  if line then
    said = { character = character, moment = moment, line = line, spoke = spoke }
  end
  if not line or (spoke and quiet) then
    return spoke
  end
  local dialogue = require("core.voice.dialogue")
  if spoke then
    keep(dialogue.speak(character, line))
  else
    dialogue.write(character, line)
  end
  return spoke
end

---Has the region's character say their line for a moment: out loud when the region has a clip
---for it (sounds/<franchise>/voices/<region>/), written otherwise, both in the dialogue box under
---their name, apart from the notifications. A spoken line stays on screen until its voice is over,
---whether the clip is cached or still on its way from Fish Audio. A moment only heard out loud
---stays quiet without its clip. While a character speaks, a louder moment cuts in, an aside stays
---quiet and anything else waits its turn (the newest, unless a louder one already waits).
---@param moment string like trial_passed, ci_failed, pushed or boss_felled
---@param vars table<string, string>|nil values for the line's holes, like branch or boss
---@param opts? { quiet?: boolean } quiet leaves the spoken words off screen, for moments that
---already show something of their own (the coach's stage, the rest)
---@return boolean spoke whether the character said it out loud, or will once the voice ends
function M.say(moment, vars, opts)
  local admission = actions.admit(speaking and speaking.priority, moment)
  if admission == "drop" then
    return false
  end
  if admission == "queue" then
    local incoming = { moment = moment, vars = vars, opts = opts, at = vim.uv.now() }
    waiting = actions.enqueue(waiting, incoming)
    return true
  end
  return say_now(moment, vars, opts)
end

---What a character said last, any way they said it.
---@return { character: string, moment: string, line: string, spoke: boolean }|nil
function M.last()
  return said
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

---Greets you on the first nvim of the day, in the voice of the day's character, and opens the
---voice studio.
function M.setup()
  require("core.voice.studio").setup()
  vim.api.nvim_create_autocmd("UIEnter", {
    group = vim.api.nvim_create_augroup("eldentree_voice", { clear = true }),
    once = true,
    callback = function()
      vim.defer_fn(greet_once_a_day, MORNING_DELAY_MS)
    end,
  })
end

return M
