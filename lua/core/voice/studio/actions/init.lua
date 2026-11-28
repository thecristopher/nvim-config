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

-- the holes every moment can fill, from the clock and the project (core.voice.actions.context).
-- They change slowly, so a take with them is worth caching ahead
M.SHARED_HOLES = { "weekday", "daypart", "repo" }

---Every hole a moment's take may use: what happened at it, then the shared ones.
---@param moment string
---@return string[]
function M.holes(moment)
  return vim.list_extend(vim.deepcopy(M.HOLES[moment] or {}), M.SHARED_HOLES)
end

-- whether a take names what happened at its moment, so it only makes sense right now
local function eventful(take, moment)
  for _, hole in ipairs(M.HOLES[moment] or {}) do
    if take:find("{" .. hole .. "}", 1, true) then
      return true
    end
  end
  return false
end

-- a voiced take that arrives later than this no longer plays, the moment has passed
M.LATE_MS = 4000

---Whether a take voiced on the spot arrived in time to be heard with its moment.
---@param elapsed_ms number since the moment asked for it
---@return boolean
function M.on_time(elapsed_ms)
  return elapsed_ms <= M.LATE_MS
end

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
---@param moment string|nil the moment, to tell which takes name what happened at it
---@return string[] lines
---@return table<string, boolean> eventful the lines that name what happened, only worth it now
---@return table<string, string> origin each line's take as written, holes and all
function M.pool(takes, fresh, vars, moment)
  local lines, now, origin = {}, {}, {}
  for _, list in ipairs({ takes or {}, fresh or {} }) do
    for _, take in ipairs(list) do
      local line = voice.fill(take, vars)
      if not line:find("{%w+}") and not origin[line] then
        origin[line] = take
        table.insert(lines, line)
        now[line] = moment and eventful(take, moment) or nil
      end
    end
  end
  return lines, now, origin
end

---The words a moment can show written when no voice can say it: every take of the script and the
---studio, without direction or tags, holes filled.
---@param takes string[]|nil
---@param fresh string[]|nil
---@param vars table<string, string>|nil
---@return string[]
function M.written(takes, fresh, vars)
  local lines = M.pool(takes, fresh, vars)
  return vim.tbl_map(M.plain, lines)
end

---A role's takes by moment without the ones banned.
---@param takes table<string, string[]>
---@param banned string[]|nil raw takes never to say again
---@return table<string, string[]>
function M.without(takes, banned)
  local never = {}
  for _, take in ipairs(banned or {}) do
    never[take] = true
  end
  local kept = {}
  for moment, list in pairs(takes or {}) do
    kept[moment] = vim.tbl_filter(function(take)
      return not never[take]
    end, list)
  end
  return kept
end

---The file name a take's audio is cached under, one per model so a better take can replace it.
---@param model string
---@param text string the take exactly as sent
---@return string
function M.cache_name(model, text)
  return ("%s-%08x-%d.mp3"):format(model, require("core.utils").hash(text), #text)
end

-- splits a moment's takes into the ones already cached, the ones nobody has heard yet that only
-- make sense now, and the ones nobody has heard yet that can wait for a later moment
local function split(lines, cached, eventful)
  local ready, now, later = {}, {}, {}
  for _, line in ipairs(lines) do
    local bucket = cached[line] and ready or (eventful[line] and now or later)
    table.insert(bucket, line)
  end
  return ready, now, later
end

---Chooses the take a moment says, whether it has to be voiced first, and a take to voice in the
---background for a later moment. A take nobody has heard waits for the network only when nothing
---is cached or it names what just happened, otherwise a cached take plays at once and the unheard
---one is voiced behind it.
---@param lines string[] from pool
---@param cached table<string, string> take to the path of its audio
---@param opts { roll: number, fresh_roll: number, last?: string|string[], can_voice: boolean, eventful?: table<string, boolean> }
---@return string|nil take
---@return boolean voice_first true when the take has no audio yet and goes to Fish Audio
---@return string|nil prefetch an unheard take to voice in the background, nil for none
function M.choose(lines, cached, opts)
  local ready, now, later = split(lines, cached, opts.eventful or {})
  local wants_fresh = #ready == 0 or opts.fresh_roll < M.FRESH_CHANCE
  if not (opts.can_voice and wants_fresh) then
    return voice.pick(ready, opts.roll, opts.last), false, nil
  end
  if #now > 0 then
    return voice.pick(now, opts.roll, opts.last), true, nil
  end
  if #later == 0 then
    return voice.pick(ready, opts.roll, opts.last), false, nil
  end
  local unheard = voice.pick(later, opts.roll, opts.last)
  if #ready == 0 then
    return unheard, true, nil
  end
  return voice.pick(ready, opts.roll, opts.last), false, unheard
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

---The clip name a script take is recorded under in the repo: the moment for the first take, then
---moment_2, moment_3, the same names the voice sheet and `spoken` use.
---@param moment string
---@param index integer the take's place in the script
---@return string
function M.clip_name(moment, index)
  return index == 1 and moment or ("%s_%d"):format(moment, index)
end

---The script takes already recorded in the repo's voice folder, take to its file name.
---@param takes table<string, string[]> the script's takes by moment
---@param files string[] file names in sounds/<franchise>/voices/<region>
---@param extensions table<string, boolean> audio extensions the player takes
---@return table<string, string>
function M.recorded(takes, files, extensions)
  local found = {}
  for moment, list in pairs(takes) do
    for index, take in ipairs(list) do
      found[take] = voice.clip_file(files, M.clip_name(moment, index), extensions)
    end
  end
  return found
end

---The cached files a prune deletes: a free take whose paid version exists, and any take no role
---says anymore once it is older than the grace period, so a branch's take outlives the day.
---@param files { name: string, age_s: integer }[] the voice folder's audio files
---@param live table<string, boolean> cache names some role can still say
---@param grace_s integer how old an orphan gets before it goes
---@return string[] names to delete
function M.prune_plan(files, live, grace_s)
  local present = {}
  for _, file in ipairs(files) do
    present[file.name] = true
  end
  local doomed = {}
  for _, file in ipairs(files) do
    local paid_twin = file.name:gsub("^s2%.1%-pro%-free%-", "drama-3-")
    local superseded = paid_twin ~= file.name and present[paid_twin]
    local orphan = not live[file.name] and file.age_s > grace_s
    if superseded or orphan then
      table.insert(doomed, file.name)
    end
  end
  return doomed
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
