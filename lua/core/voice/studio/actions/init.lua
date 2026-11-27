-- Pure logic of the voice studio: which take a moment plays, how a take reads on screen and on a
-- model that has no paired tags, and where its audio is cached.
local voice = require("core.voice.actions")

local M = {}

-- the holes a moment can fill with what really happened, the rest of the moments have none
M.HOLES = {
  committed = { "branch" },
  pushed = { "branch" },
  ci_passed = { "branch" },
  ci_failed = { "branch" },
  pr_opened = { "number" },
  boss_felled = { "boss" },
}

-- how often a moment says a take nobody has heard yet when it has both kinds, the rest of the time
-- it plays one already cached so most moments sound at once and cost nothing
M.FRESH_CHANCE = 0.35

-- Drama 3 shapes words with paired tags, the free model only reads cues placed before them
local S2_CUES = {
  emphasis = "emphasis",
  stress = "emphasis",
  forceful = "emphasis",
  whisper = "whispering",
  soft = "soft tone",
  slow = "soft tone",
  fast = "in a hurry tone",
}

---What a take reads like on screen: the words alone, without its direction or tags.
---@param text string a take with Drama 3 markup
---@return string
function M.plain(text)
  local words = text:gsub("%b[]", ""):gsub("</?%a+>", "")
  return vim.trim((words:gsub("%s+", " "):gsub(" ([.,!?])", "%1")))
end

---Rewrites a take for the model that will say it: Drama 3 keeps it whole, any other model gets its
---paired tags turned into the cue placed before the words.
---@param text string a take with Drama 3 markup
---@param model string like drama-3 or s2.1-pro-free
---@return string
function M.for_model(text, model)
  if model == "drama-3" then
    return text
  end
  return (
    text:gsub("<(%a+)>(.-)</%1>", function(tag, words)
      local cue = S2_CUES[tag]
      return cue and ("[%s] %s"):format(cue, words) or words
    end)
  )
end

---Turns a branch into words a voice can say: no folder prefix, no ticket key, spaces for dashes.
---@param branch string like fix/DEVOPS-1869-axios-main
---@return string like axios main
function M.speakable_branch(branch)
  local name = branch:match("([^/]+)$") or branch
  name = name:gsub("^%u+%-%d+[%-_]?", "")
  return vim.trim((name:gsub("[%-_]+", " ")))
end

---Every take a moment can play right now: the script's and the studio's fresh ones, holes filled
---with what happened. A take whose holes cannot be filled is left out, and none comes twice.
---@param takes string[]|nil the script's takes for the moment
---@param fresh string[]|nil takes the studio wrote later for it
---@param vars table<string, string>|nil values for the holes, like branch or boss
---@return string[]
function M.pool(takes, fresh, vars)
  local seen, lines = {}, {}
  for _, list in ipairs({ takes or {}, fresh or {} }) do
    for _, take in ipairs(list) do
      local line = voice.fill(take, vars)
      if not line:find("{%w+}") and not seen[line] then
        seen[line] = true
        table.insert(lines, line)
      end
    end
  end
  return lines
end

---The file name a take's audio is cached under, one per model so a better take can replace it.
---@param model string
---@param text string the take exactly as sent
---@return string
function M.cache_name(model, text)
  return ("%s-%08x-%d.mp3"):format(model, require("core.utils").hash(text), #text)
end

-- splits a moment's takes into the ones already cached and the ones nobody has heard yet
local function split(lines, cached)
  local ready, unheard = {}, {}
  for _, line in ipairs(lines) do
    table.insert(cached[line] and ready or unheard, line)
  end
  return ready, unheard
end

---Chooses the take a moment says and whether it has to be voiced first.
---@param lines string[] from pool
---@param cached table<string, string> take to the path of its audio
---@param opts { roll: number, fresh_roll: number, last?: string, can_voice: boolean }
---@return string|nil take
---@return boolean voice_first true when the take has no audio yet and goes to Fish Audio
function M.choose(lines, cached, opts)
  local ready, unheard = split(lines, cached)
  local wants_fresh = #ready == 0 or opts.fresh_roll < M.FRESH_CHANCE
  if opts.can_voice and #unheard > 0 and wants_fresh then
    return voice.pick(unheard, opts.roll, opts.last), true
  end
  if #ready > 0 then
    return voice.pick(ready, opts.roll, opts.last), false
  end
  return nil, false
end

---The next take to cache ahead of time: the first one, in the script's order, without audio from
---the paid model. Takes with holes wait for the moment, they depend on what happens.
---@param moments string[] in the order to bake them
---@param takes table<string, string[]> the script's takes by moment
---@param fresh table<string, string[]> the studio's fresh takes by moment
---@param has_paid fun(text: string): boolean whether a take already has the paid model's audio
---@return string|nil
function M.next_to_bake(moments, takes, fresh, has_paid)
  for _, source in ipairs({ takes, fresh }) do
    for _, moment in ipairs(moments) do
      for _, take in ipairs(source[moment] or {}) do
        if not take:find("{%w+}") and not has_paid(take) then
          return take
        end
      end
    end
  end
  return nil
end

---How much of a role is voiced: takes with audio out of every take it can cache ahead.
---@param takes table<string, string[]>
---@param fresh table<string, string[]>
---@param has_audio fun(text: string): boolean
---@return integer voiced
---@return integer total
function M.coverage(takes, fresh, has_audio)
  local voiced, total = 0, 0
  for _, source in ipairs({ takes, fresh }) do
    for _, list in pairs(source) do
      for _, take in ipairs(list) do
        if not take:find("{%w+}") then
          total = total + 1
          voiced = voiced + (has_audio(take) and 1 or 0)
        end
      end
    end
  end
  return voiced, total
end

return M
