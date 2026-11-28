-- Pure logic of the studio's writer: the prompt that asks Claude for fresh takes in a character's
-- voice, and how its answer joins the takes the role already has.
local check = require("core.voice.studio.actions.check")
local studio = require("core.voice.studio.actions")

local M = {}

-- moments asked for in one run, so a run stays short and every moment gets its turn
M.MOMENTS_PER_RUN = 8
-- fresh takes kept per moment, the oldest without audio leave first
M.MAX_FRESH = 6
-- candidates asked per moment, the first one that passes the checks is kept
M.CANDIDATES = 3

-- what happened at each moment, in the words the prompt uses
M.CONTEXT = {
  trial_started = "his test suite just started running",
  trial_passed = "every test in his suite passed",
  trial_failed = "his tests failed",
  committing = "Claude is drafting his commit message",
  committed = "his commit was saved",
  pushed = "his branch was pushed to the remote",
  pr_drafting = "Claude is drafting his pull request",
  pr_opened = "his pull request was opened",
  ci_passed = "CI passed on his branch",
  ci_failed = "CI failed on his branch",
  conflicts_cleared = "he resolved every merge conflict",
  lesson_started = "a coding lesson (back to basics) is starting",
  solved = "he solved an exercise of the lesson",
  solved_twice = "he solved two exercises in a row",
  solved_thrice = "he solved three exercises in a row",
  solve_failed = "his answer to an exercise was wrong",
  hint = "he bought a hint for the exercise",
  lesson_done = "the lesson is over",
  boss_appeared = "a boss appeared because errors piled up in his file",
  boss_felled = "he fixed every error and the boss fell",
  title_shown = "the title screen of the editor is showing",
  morning = "he opened the editor for the first time today",
  region_arrived = "he chose this character's place for today",
  traveled = "he switched to another repository",
  resting = "the editor went idle and he is taking a break",
  woke = "he came back to the keyboard after a break",
  expedition = "a silent focus session (an expedition) is starting",
  map_opened = "he opened the map of the project",
  bestiary_opened = "he opened the bestiary of errors he has defeated",
  chronicle_opened = "he opened the chronicle of his past days",
  message_written = "he left a message on a line of code, like the messages on the ground in Souls games",
  claude_asked = "he asked Claude to review his pull request",
}

---The section of a voice sheet about one character, from its heading to the next one.
---@param markdown string a voice sheet from docs/voices
---@param character string like Claire Redfield or Magik
---@return string|nil
function M.sheet_section(markdown, character)
  local first = vim.split(character, " ", { plain = true })[1]
  local sections = vim.split(markdown, "\n## ", { plain = true })
  for _, section in ipairs(sections) do
    local heading = section:match("^[^\n]*")
    if heading:find(character, 1, true) or heading:find(first, 1, true) then
      return "## " .. section
    end
  end
  return nil
end

---The moments to write for next: the ones with the fewest fresh takes, in the script's order.
---@param moments string[] in the script's order
---@param fresh table<string, string[]> the studio's fresh takes by moment
---@param count integer how many to pick
---@return string[]
function M.moments_to_write(moments, fresh, count)
  local ranked = vim.deepcopy(moments)
  local position = {}
  for index, moment in ipairs(moments) do
    position[moment] = index
  end
  table.sort(ranked, function(a, b)
    local fewer_a, fewer_b = #(fresh[a] or {}), #(fresh[b] or {})
    if fewer_a ~= fewer_b then
      return fewer_a < fewer_b
    end
    return position[a] < position[b]
  end)
  return vim.list_slice(ranked, 1, count)
end

-- what each shared hole says, so a take knows when it can use one
local SHARED = {
  weekday = "the day of the week, like Monday",
  daypart = "morning, afternoon, evening or night",
  repo = "the project's name, read as words",
}

-- the holes a moment can use, the one that says what happened first
local function hole_brief(moment)
  local lines = {}
  for _, hole in ipairs(studio.HOLES[moment] or {}) do
    table.insert(
      lines,
      ("  Say the real {%s} with that exact hole in one candidate at least."):format(hole)
    )
  end
  local shared = vim.tbl_map(function(hole)
    return ("{%s} (%s)"):format(hole, SHARED[hole])
  end, studio.SHARED_HOLES)
  table.insert(lines, "  You may also use " .. table.concat(shared, ", ") .. ".")
  return lines
end

-- one moment of the prompt: what happened, the holes it may use and the takes to never repeat
local function moment_brief(moment, takes, fresh)
  local lines = { ("- %s: %s."):format(moment, M.CONTEXT[moment] or moment) }
  vim.list_extend(lines, hole_brief(moment))
  for _, take in ipairs(vim.list_extend(vim.deepcopy(takes or {}), fresh or {})) do
    table.insert(lines, "  Already said: " .. take)
  end
  return table.concat(lines, "\n")
end

-- the takes Cris banned, the kind of line never to write again
local function banned_brief(banned)
  if not banned or #banned == 0 then
    return nil
  end
  local lines = { "He disliked these lines, never write anything like them:" }
  for _, take in ipairs(banned) do
    table.insert(lines, "- " .. take)
  end
  return table.concat(lines, "\n")
end

---The prompt that asks Claude for one fresh take per moment in a character's voice.
---@param brief { character: string, world: string, sheet: string|nil, bond: string|nil, moments: string[], takes: table<string, string[]>, fresh: table<string, string[]>, banned?: string[] }
---@return string
function M.prompt(brief)
  local parts = {
    ("You write the spoken lines of %s (%s), the voice that reacts out loud to a developer named Cris while he works in Neovim."):format(
      brief.character,
      brief.world
    ),
  }
  if brief.sheet then
    table.insert(parts, "Who the character is and how they talk:\n" .. brief.sheet)
  end
  if brief.bond then
    table.insert(parts, "The relationship:\n" .. brief.bond:gsub("{character}", brief.character))
  end
  table.insert(
    parts,
    table.concat({
      "Rules for every line:",
      "- English, at most 25 words, one to three short sentences, said to him.",
      "- Say what just happened in words he recognizes, in the character's own world.",
      "- Call him Cris only now and then, a pet name the character uses is fine too.",
      "- Fish Audio Drama 3 markup: one [direction] at the start written the way you'd say it to an actor, at most one <emphasis>word</emphasis> or <whisper>words</whisper>, and [break] for a pause.",
      "- New ideas only: never repeat or paraphrase a line marked as already said, nor each other.",
      "- No em dashes, no quotes around the line.",
    }, "\n")
  )
  local banned = banned_brief(brief.banned)
  if banned then
    table.insert(parts, banned)
  end
  local moments = {}
  for _, moment in ipairs(brief.moments) do
    table.insert(moments, moment_brief(moment, brief.takes[moment], brief.fresh[moment]))
  end
  table.insert(parts, "Moments:\n" .. table.concat(moments, "\n"))
  table.insert(
    parts,
    ("Answer with only a JSON object mapping each moment name to an array of %d different candidate lines, best first, nothing else."):format(
      M.CANDIDATES
    )
  )
  return table.concat(parts, "\n\n")
end

-- the candidates Claude answered for a moment, one line or a list of them
local function candidates(answer)
  if type(answer) == "string" then
    return { answer }
  end
  return type(answer) == "table" and answer or {}
end

---The fresh takes in Claude's answer, the first candidate per moment that passes the checks, the
---rest thrown away.
---@param stdout string|nil the answer, a JSON object possibly wrapped in prose or a code fence
---@param moments string[] the moments that were asked
---@param known? table<string, string[]> what each moment already has, banned takes too, so a
---paraphrase of one never joins
---@return table<string, string>
function M.parse(stdout, moments, known)
  local json = (stdout or ""):match("%b{}")
  local ok, data = pcall(vim.json.decode, json or "")
  if not ok or type(data) ~= "table" then
    return {}
  end
  local takes = {}
  for _, moment in ipairs(moments) do
    for _, candidate in ipairs(candidates(data[moment])) do
      if check.usable(candidate, moment, (known or {})[moment]) then
        takes[moment] = vim.trim(candidate)
        break
      end
    end
  end
  return takes
end

-- drops takes from the front until the list fits, the oldest without audio first
local function trim(list, has_audio)
  while #list > M.MAX_FRESH do
    local doomed = 1
    for index, take in ipairs(list) do
      if not has_audio(take) then
        doomed = index
        break
      end
    end
    table.remove(list, doomed)
  end
  return list
end

---Adds new takes to a role's fresh ones, keeping at most MAX_FRESH per moment, newest last. The
---oldest take nobody voiced yet leaves first, so paid audio is not thrown away while a take without
---any could go instead.
---@param fresh table<string, string[]> the role's fresh takes by moment
---@param new table<string, string> one take per moment
---@param has_audio? fun(take: string): boolean whether a take is voiced, none are when nil
---@return table<string, string[]>
function M.merge(fresh, new, has_audio)
  has_audio = has_audio or function()
    return false
  end
  local merged = vim.deepcopy(fresh or {})
  for moment, take in pairs(new) do
    local list = merged[moment] or {}
    if not vim.tbl_contains(list, take) then
      table.insert(list, take)
    end
    merged[moment] = trim(list, has_audio)
  end
  return merged
end

---Joins two libraries of fresh takes, by role then moment, the way an import adds to what is here.
---A take banned here never comes back with an import.
---@param here table<string, table<string, string[]>>
---@param incoming table<string, table<string, string[]>>
---@param banned? table<string, string[]> raw takes banned per role
---@return table<string, table<string, string[]>>
function M.join(here, incoming, banned)
  local joined = vim.deepcopy(here or {})
  for role, moments in pairs(incoming or {}) do
    local never = studio.without(moments, (banned or {})[role])
    local merged = joined[role] or {}
    for moment, takes in pairs(never) do
      for _, take in ipairs(takes) do
        merged = M.merge(merged, { [moment] = take })
      end
    end
    joined[role] = merged
  end
  return joined
end

return M
