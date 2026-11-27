local M = {}

-- every moment a character speaks up for, :checkhealth asks each region for all of them
-- holes: {branch} for ci, pushed and committed, {boss} for boss_felled, {number} for pr_opened
M.MOMENTS = {
  "trial_passed",
  "trial_failed",
  "ci_passed",
  "ci_failed",
  "pushed",
  "boss_felled",
  "committed",
  "pr_opened",
  "region_arrived",
  "morning",
  "conflicts_cleared",
  "woke",
}

-- moments only heard out loud: a region speaks at them when it has a clip for them, and stays
-- quiet otherwise, so :checkhealth asks no region for them
M.SPOKEN = {
  "lesson_started",
  "lesson_done",
  "solved",
  "solved_twice",
  "solved_thrice",
  "solve_failed",
  "hint",
  "boss_appeared",
  "resting",
  "expedition",
  "traveled",
  "committing",
  "pr_drafting",
  "trial_started",
  "claude_asked",
  "map_opened",
  "bestiary_opened",
  "chronicle_opened",
  "message_written",
  "title_shown",
}

---Picks one of the lines, never the one said last when there is another to say.
---@param lines string[]|nil
---@param roll number between 0 and 1, where in the list to land
---@param last string|nil the line said last time
---@return string|nil
function M.pick(lines, roll, last)
  local fresh = vim.tbl_filter(function(line)
    return line ~= last
  end, lines or {})
  if #fresh == 0 then
    fresh = lines or {}
  end
  if #fresh == 0 then
    return nil
  end
  return fresh[math.min(#fresh, math.floor(roll * #fresh) + 1)]
end

-- a written line stays at least this long in the dialogue box, and a spoken one too
M.SHOWN_MIN_MS = 4000
-- and a moment after the voice ends, so the last words can still be read
M.LINGER_MS = 1200
-- a voice that never says it ended (a hung request, a lost player) lets go of its words here
M.SHOWN_MAX_MS = 60000

-- a written line stays a little longer for every character it has, so a long one can be read
M.READ_MS_PER_CHAR = 45

---How long a written line stays in the dialogue box: long enough to read it, never under the
---shortest stay.
---@param line string
---@return integer
function M.reading_ms(line)
  return math.max(M.SHOWN_MIN_MS, vim.fn.strchars(line) * M.READ_MS_PER_CHAR)
end

---How long a spoken line waits to leave the dialogue box once the voice is over.
---@param shown_ms number how long it has been on screen
---@return integer
function M.linger(shown_ms)
  return math.max(M.LINGER_MS, M.SHOWN_MIN_MS - math.floor(shown_ms))
end

---Tells whether today's first greeting is still due, from the day the last one was said.
---@param said_on string|nil the day of the last greeting, as YYYY-MM-DD
---@param today string as YYYY-MM-DD
---@return boolean
function M.morning_due(said_on, today)
  return vim.trim(said_on or "") ~= today
end

---Fills the {name} holes of a line, leaving the ones it has no value for.
---@param line string
---@param vars table<string, string>|nil
---@return string
function M.fill(line, vars)
  return (line:gsub("{(%w+)}", function(key)
    return vars and vars[key] or nil
  end))
end

---The line the character of a region says for a moment, nil when they have nothing for it.
---@param voices table|nil lines by region name, then by moment
---@param region string region name
---@param moment string like trial_passed or pushed
---@param roll number between 0 and 1
---@param last string|nil the line said last time
---@return string|nil
function M.line(voices, region, moment, roll, last)
  local lines = ((voices or {})[region] or {})[moment]
  return M.pick(lines, roll, last)
end

---The clip the character of a region says out loud for a moment, with its words. A region's
---`spoken` maps each moment to its clips, by file name (without extension) to what it says.
---@param voices table|nil lines by region name, then by moment, plus the region's spoken
---@param region string region name
---@param moment string like morning or solved
---@param roll number between 0 and 1
---@param last string|nil the clip played last time
---@return string|nil clip file name without extension
---@return string|nil line what the clip says
function M.clip(voices, region, moment, roll, last)
  local clips = (((voices or {})[region] or {}).spoken or {})[moment] or {}
  local names = vim.tbl_keys(clips)
  table.sort(names)
  local name = M.pick(names, roll, last)
  return name, name and clips[name]
end

---The file a clip plays among the files of a region's voice folder, nil when it is missing.
---@param files string[] file names in sounds/<franchise>/voices/<region>
---@param clip string file name without extension
---@param extensions table<string, boolean> the audio extensions a player takes
---@return string|nil
function M.clip_file(files, clip, extensions)
  for _, file in ipairs(files) do
    local stem, extension = file:match("^(.+)%.(%w+)$")
    if stem == clip and extensions[extension:lower()] then
      return file
    end
  end
  return nil
end

-- the dialogue box never runs wider than this share of the editor, a longer line wraps
M.DIALOGUE_SHARE = 0.6
-- nor narrower than this, so a short line still reads as a box
M.DIALOGUE_MIN_WIDTH = 24
-- empty rows between the box and the statusline
M.DIALOGUE_GAP = 1

---Where the dialogue box sits and what it shows: centered at the bottom, right above the
---statusline, wrapped to its width with a cell of padding on each side.
---@param line string what the character says
---@param title string|nil the character's name on the frame, the box is at least as wide
---@param columns integer the editor's width
---@param lines integer the editor's height
---@param bottom_rows integer rows taken under the box (statusline and command line)
---@return { row: integer, col: integer, width: integer, height: integer, lines: string[] }
function M.dialogue_place(line, title, columns, lines, bottom_rows)
  local limit = math.max(M.DIALOGUE_MIN_WIDTH, math.floor(columns * M.DIALOGUE_SHARE)) - 2
  local wrapped = require("core.progress.actions").wrap(line, limit)
  local shown, widest = {}, vim.fn.strdisplaywidth(title or "") + 2
  for _, text in ipairs(vim.split(wrapped, "\n", { plain = true })) do
    table.insert(shown, " " .. text)
    widest = math.max(widest, vim.fn.strdisplaywidth(text))
  end
  local width = math.min(math.max(widest + 2, M.DIALOGUE_MIN_WIDTH), columns - 2)
  -- the frame takes a row above and below and a column on each side
  return {
    row = math.max(0, lines - bottom_rows - M.DIALOGUE_GAP - #shown - 2),
    col = math.max(0, math.floor((columns - width - 2) / 2)),
    width = width,
    height = #shown,
    lines = shown,
  }
end

return M
