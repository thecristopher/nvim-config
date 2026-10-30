-- Pure pieces of the back-to-basics bridge: the coach of the franchise, its sounds, the fanfare
-- of a solve and how a lesson reads as a HUD item.
local M = {}

-- the coach reuses sounds the franchise already has, first match wins, a moment with no match
-- stays quiet. Opening the stage rings the spirit calling bell where there is one: the coach is summoned.
-- Failing twice in a row gets a word of comfort where the coach has one
M.SOUNDS = {
  coach_open = { "summon", "hud_open" },
  ready = { "hud_select" },
  hint = { "hud_select" },
  failed = { "hud_back" },
  failed_again = { "comfort", "hud_back" },
  skip = { "hud_close" },
}

-- what the statusline shows while the next exercise gets ready in the background
local AHEAD_ICONS = { forge = "󰈸", brief = "󰭹" }

local STATE_ICONS = { mastered = "★", due = "↻", solved = "✓", started = "~", new = "·" }

---The persona that coaches in a franchise, nil when the lore names none.
---@param lore table franchise lore
---@return string|nil
function M.persona_of(lore)
  local persona = lore.coach and lore.coach.persona
  if persona == nil or persona == "" then
    return nil
  end
  return persona
end

---The franchise sounds that may play for a coach event, in order of preference.
---@param event string "coach_open" or a moment like "failed"
---@return string[]|nil
function M.sound_for(event)
  return M.SOUNDS[event]
end

-- what the banner says under its big word: the exercise beaten and what it paid
local function subtitle(result)
  local xp = (result.xp or 0) > 0 and ("+%d XP"):format(result.xp) or nil
  if result.level_up then
    return ("level %d cleared"):format(result.level_up) .. (xp and ("  ·  " .. xp) or "")
  end
  local parts = {}
  table.insert(parts, result.title)
  table.insert(parts, xp)
  return #parts > 0 and table.concat(parts, "  ·  ") or nil
end

---The rank of a finished day: S for a flawless one at the XP goal, D when skips outweigh solves.
---@param day { solved: integer, clean: integer, skipped: integer, hints: integer, xp: integer, goal?: integer }
---@return string
function M.day_rank(day)
  local fought = day.solved + day.skipped
  local clean_share = fought > 0 and day.clean / fought or 0
  local at_goal = (day.xp or 0) >= (day.goal or 0)
  if clean_share == 1 and day.hints == 0 and at_goal then
    return "S"
  end
  if clean_share >= 0.75 and day.skipped == 0 then
    return "A"
  end
  if clean_share >= 0.5 then
    return "B"
  end
  return day.solved > day.skipped and "C" or "D"
end

---The banner, its subtitle and the runes a solve is worth. A redo or a failure earns nothing.
---@param result table the User BtbResult payload
---@return { banner: string|nil, subtitle: string|nil, runes: integer }
function M.celebration(result)
  if not result.ok or result.redo then
    return { banner = nil, subtitle = nil, runes = 0 }
  end
  local banner = nil
  if result.level_up or result.day then
    banner = "great"
  elseif result.outcome == "clean" then
    banner = "felled"
  end
  local words = banner and subtitle(result) or nil
  if result.day then
    -- the pass that ends the day closes it with its rank
    words = ("day cleared  ·  rank %s"):format(M.day_rank(result.day))
      .. (words and ("  ·  " .. words) or "")
  end
  return { banner = banner, subtitle = words, runes = result.xp or 0 }
end

---Where a persona's portrait lives in the config.
---@param config_dir string
---@param persona { portrait?: string }
---@return string|nil
function M.portrait_file(config_dir, persona)
  if not persona or not persona.portrait then
    return nil
  end
  return config_dir .. "/images/portraits/" .. persona.portrait
end

-- the portraits are 276x336 and a terminal cell is about twice as tall as it is wide
M.PORTRAIT_COLUMNS_PER_ROW = 1.64

---Where the portrait sits inside the stage's portrait window: as big as fits without stretching,
---centered, so it reads the same on a laptop split or a wide monitor.
---@param width integer columns of the window
---@param height integer rows of the window
---@return { row: integer, col: integer, width: integer, height: integer }
function M.portrait_anchor(width, height)
  local fit_width = math.min(width, math.floor(height * M.PORTRAIT_COLUMNS_PER_ROW + 0.5))
  local fit_height = math.min(height, math.floor(fit_width / M.PORTRAIT_COLUMNS_PER_ROW + 0.5))
  return {
    row = math.floor((height - fit_height) / 2),
    col = math.floor((width - fit_width) / 2),
    width = math.max(1, fit_width),
    height = math.max(1, fit_height),
  }
end

---How a lesson reads in the HUD: icon by state, title, level and concepts.
---@param entry table one of btb lessons --json
---@return { icon: string, name: string, count: integer|nil, desc: string }
function M.hud_fields(entry)
  return {
    icon = STATE_ICONS[entry.state] or "·",
    name = entry.title,
    count = entry.level ~= 0 and entry.level or nil,
    desc = table.concat(entry.concepts or {}, ", "),
  }
end

---The lessons worth showing in the HUD: started or solved ones first, newest solves on top.
---@param entries table[] btb lessons --json
---@param limit integer
---@return table[]
function M.hud_lessons(entries, limit)
  local fought = vim.tbl_filter(function(entry)
    return entry.state ~= "new" and entry.lesson ~= nil
  end, entries)
  table.sort(fought, function(a, b)
    return (a.solvedAt or "") > (b.solvedAt or "")
  end)
  return vim.list_slice(fought, 1, limit)
end

---The statusline piece for the work btb does ahead, empty once it is done or failed.
---@param ahead table|nil the data of the last User BtbAhead
---@return string
function M.ahead_text(ahead)
  local icon = ahead and AHEAD_ICONS[ahead.step]
  if not icon then
    return ""
  end
  return ahead.label and (icon .. " " .. ahead.label) or icon
end

---What is left of the day, from btb today: new exercises and reviews still pending, and the streak.
---@param today table|nil btb today --json
---@return { new: integer, reviews: integer, streak: integer, done: boolean }|nil
function M.day_status(today)
  if not today or today.error or not today.queue then
    return nil
  end
  local status = { new = 0, reviews = 0, streak = today.streak or 0 }
  for _, item in ipairs(today.queue) do
    if not item.done then
      local kind = item.review and "reviews" or "new"
      status[kind] = status[kind] + 1
    end
  end
  status.done = status.new + status.reviews == 0
  return status
end

---How the HUD's training key reads the day: what is left and the streak.
---@param status table|nil from day_status
---@return string|nil nil when btb has not answered yet
function M.day_line(status)
  if not status then
    return nil
  end
  local streak = status.streak > 0 and ("streak %d"):format(status.streak) or nil
  if status.done then
    return table.concat(
      vim.tbl_filter(function(part)
        return part ~= nil
      end, { "Done for today ✓", streak }),
      " · "
    )
  end
  local parts = {}
  if status.new > 0 then
    table.insert(parts, ("%d new"):format(status.new))
  end
  if status.reviews > 0 then
    table.insert(
      parts,
      ("%d %s"):format(status.reviews, status.reviews == 1 and "review" or "reviews")
    )
  end
  table.insert(parts, streak)
  return table.concat(parts, " · ")
end

local NODES = {
  done = { "◆", "EldenMapCleared" },
  current = { "◈", "DiagnosticWarn" },
  ahead = { "◇", "Comment" },
}

local function level_state(level, current)
  if level.done then
    return "done"
  end
  return level.level == current and "current" or "ahead"
end

local function chain_line(track)
  local line, marks = "   ", {}
  for index, level in ipairs(track.levels) do
    local node = NODES[level_state(level, track.current)]
    table.insert(marks, { col = #line, end_col = #line + #node[1], group = node[2] })
    line = line .. node[1]
    if index < #track.levels then
      line = line .. "━━"
    end
  end
  return line, marks
end

local function current_level(track)
  for _, level in ipairs(track.levels) do
    if level.level == track.current then
      return level
    end
  end
  return nil
end

local function track_note(track)
  if track.locked then
    return "   locked for now"
  end
  if not track.drawn then
    return ("   no path yet, :Btb placement %s draws it"):format(track.id)
  end
  local level = current_level(track)
  if not level then
    return "   every level cleared"
  end
  return ("   level %d · %s · %d/%d clean"):format(
    level.level,
    level.title,
    level.clean,
    level.target
  )
end

---The path map of every track, as lines with their highlights: a chain of levels per track,
---cleared ones blue, the current one lit, the ones ahead in the fog.
---@param status table btb status --json
---@return string[] lines
---@return { row: integer, col: integer, end_col: integer, group: string }[] marks zero based rows
function M.path_map(status)
  local lines, marks = {}, {}
  for _, track in ipairs(status.tracks or {}) do
    table.insert(marks, { row = #lines, col = 1, end_col = 1 + #track.title, group = "Title" })
    table.insert(lines, " " .. track.title)
    if track.drawn and not track.locked and #(track.levels or {}) > 0 then
      local line, chain = chain_line(track)
      for _, mark in ipairs(chain) do
        table.insert(marks, vim.tbl_extend("force", mark, { row = #lines }))
      end
      table.insert(lines, line)
    end
    table.insert(lines, track_note(track))
    table.insert(lines, "")
  end
  return lines, marks
end

---Names the onsite fight: the region's boss, then the franchise's word for the onsite.
---@param boss string
---@param coach { onsite: string }
---@return string
function M.onsite_name(boss, coach)
  return ("%s  ·  %s"):format(boss, coach.onsite)
end

---What the merchant asks before a hint, nil when there is nothing left to sell.
---@param coach { hint: string } the franchise's coach words
---@param info { hints_left?: integer, cost?: integer }
---@return string|nil
function M.hint_offer(coach, info)
  if info.hints_left == 0 then
    return nil
  end
  return coach.hint:format(info.cost or 0)
end

local STANDINGS = {
  weak = { "□", "EldenMapLeft" },
  learning = { "▣", "EldenMapPath" },
  owned = { "■", "EldenMapCleared" },
}

local function concept_line(row, width)
  local glyph = STANDINGS[row.standing] or STANDINGS.learning
  local name = row.concept .. (" "):rep(math.max(0, width - vim.api.nvim_strwidth(row.concept)))
  local tally = ("✓%d  ✗%d"):format(row.clean, row.struggled + row.skipped)
  local line = (" %s %s  %s"):format(glyph[1], name, tally)
  return line, 1 + #glyph[1] + 1 + #name, glyph[2]
end

local function widest(rows)
  local width = 0
  for _, row in ipairs(rows) do
    width = math.max(width, vim.api.nvim_strwidth(row.concept))
  end
  return width
end

---The concepts fought so far as rooms, per track: red the ones that cost you, blue the owned ones.
---@param concepts table[] btb status --json concepts, as { track, concept, clean, struggled, skipped, standing }
---@return string[] lines
---@return { row: integer, col: integer, end_col: integer, group: string }[] marks zero based rows
---@return table<integer, string> tracks the track of each concept row, by one based line
function M.concept_map(concepts)
  local lines, marks, tracks = {}, {}, {}
  local width, track = widest(concepts), nil
  for _, row in ipairs(concepts) do
    if row.track ~= track then
      track = row.track
      if #lines > 0 then
        table.insert(lines, "")
      end
      table.insert(marks, { row = #lines, col = 1, end_col = 1 + #track, group = "Title" })
      table.insert(lines, " " .. track)
    end
    local line, name_end, group = concept_line(row, width)
    table.insert(marks, { row = #lines, col = 0, end_col = name_end, group = group })
    table.insert(lines, line)
    tracks[#lines] = track
  end
  return lines, marks, tracks
end

return M
