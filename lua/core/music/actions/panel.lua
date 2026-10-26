-- The now playing panel's layout: the cover with the song beside it, the lyrics between two
-- dividers, the keys last. Every piece that moves (equalizer, progress, lyrics) builds on its own so
-- the panel can redraw it alone. Pieces come back as { lines, marks } with rows counted from the
-- piece's first line. Pure logic only.
local M = {}

M.WIDTH = 52
M.LYRIC_ROWS = 5
-- terminal cells are about twice as tall as wide, so 16 by 8 reads as a square
M.COVER = { row = 0, col = 1, width = 16, height = 8 }
-- zero based rows of the pieces that move, the divider sits right under the cover
M.ROWS = { state = 4, progress = 6, lyrics = M.COVER.height + 1 }
M.HEIGHT = M.ROWS.lyrics + M.LYRIC_ROWS + 2

local TEXT_COL = M.COVER.col + M.COVER.width + 2
local ROOM = M.WIDTH - TEXT_COL - 1
local SOURCES = { cider = "Cider", music = "Music" }
local BARS = { "▁", "▂", "▃", "▄", "▅", "▆", "▇", "█" }
local EQ_BARS = 6
local LYRIC_ICON = "󰝚"
local MIDDLE = math.ceil(M.LYRIC_ROWS / 2)
-- one step dimmer per row away from the sung line
local DEPTH = { "EldenMusicLyricNear", "EldenMusicLyricFar" }

--- Cuts text to a width in characters, marking the cut.
---@param text string
---@param width integer
---@return string
function M.fit(text, width)
  if vim.fn.strchars(text) <= width then
    return text
  end
  return vim.fn.strcharpart(text, 0, width - 1) .. "…"
end

--- Writes seconds the way players show them.
---@param seconds number
---@return string like 1:02
function M.clock(seconds)
  seconds = math.max(0, math.floor(seconds))
  return ("%d:%02d"):format(math.floor(seconds / 60), seconds % 60)
end

-- joins pieces of text into one line after some padding, marking each piece that has a group
local function segments_line(pad, segments)
  local line, marks = (" "):rep(pad), {}
  for _, segment in ipairs(segments) do
    local text, group = segment[1], segment[2]
    if text ~= "" and group then
      table.insert(marks, { row = 0, col = #line, end_col = #line + #text, group = group })
    end
    line = line .. text
  end
  return { lines = { line }, marks = marks }
end

local function width_of(segments)
  local width = 0
  for _, segment in ipairs(segments) do
    width = width + vim.fn.strdisplaywidth(segment[1])
  end
  return width
end

--- Picks the equalizer bar heights for a moment, flat while the song is paused.
---@param ms integer milliseconds the equalizer has been dancing
---@param playing boolean
---@return integer[] heights from 1 to 8
function M.equalizer(ms, playing)
  local heights = {}
  for i = 1, EQ_BARS do
    heights[i] = 1
  end
  if not playing then
    return heights
  end
  for i = 1, EQ_BARS do
    -- two waves out of step per bar, so no two bars move together
    local wave = (math.sin(ms / 170 + i * 1.7) + math.sin(ms / 95 + i * 0.6)) / 4 + 0.5
    heights[i] = math.floor(wave * (#BARS - 1) + 0.5) + 1
  end
  return heights
end

--- Builds the equalizer and the player state beside it.
---@param track { playing: boolean }
---@param source string|nil "cider" or "music"
---@param ms integer milliseconds the equalizer has been dancing
---@return { lines: string[], marks: table[] }
function M.state_row(track, source, ms)
  local segments = {}
  for _, height in ipairs(M.equalizer(ms, track.playing)) do
    table.insert(segments, { BARS[height], height > 4 and "EldenMusicEqHigh" or "EldenMusicEqLow" })
  end
  local state = track.playing and "󰐊 Playing" or "󰏤 Paused"
  if SOURCES[source] then
    state = state .. " in " .. SOURCES[source]
  end
  table.insert(segments, { "  " })
  table.insert(segments, { M.fit(state, ROOM - EQ_BARS - 2), "EldenMusicState" })
  return segments_line(TEXT_COL, segments)
end

--- Builds the progress bar with the elapsed and total time at its ends.
---@param elapsed number|nil seconds into the song, nil leaves the row empty
---@param duration number|nil seconds the song lasts, nil shows only the elapsed time
---@param bar { done: string, head: string, left: string } from the skin's music table
---@return { lines: string[], marks: table[] }
function M.progress_row(elapsed, duration, bar)
  if not elapsed then
    return { lines = { "" }, marks = {} }
  end
  local now = M.clock(elapsed)
  if not duration or duration <= 0 then
    return segments_line(TEXT_COL, { { now, "EldenMusicTime" } })
  end
  local total = M.clock(duration)
  local width = ROOM - #now - #total - 2
  local done = math.floor(math.min(elapsed / duration, 1) * (width - 1) + 0.5)
  return segments_line(TEXT_COL, {
    { now .. " ", "EldenMusicTime" },
    { bar.done:rep(done), "EldenMusicBarDone" },
    { bar.head, "EldenMusicBarHead" },
    { bar.left:rep(width - 1 - done), "EldenMusicBarLeft" },
    { " " .. total, "EldenMusicTime" },
  })
end

--- Builds a divider across the panel with the skin's gem in the middle.
---@param divider { line: string, gem: string } from the skin's music table
---@return { lines: string[], marks: table[] }
function M.divider(divider)
  local gem = " " .. divider.gem .. " "
  local side = M.WIDTH - 2 - vim.fn.strdisplaywidth(gem)
  local left = math.floor(side / 2)
  return segments_line(1, {
    { divider.line:rep(left), "EldenMusicDivider" },
    { gem, "EldenMusicDividerGem" },
    { divider.line:rep(side - left), "EldenMusicDivider" },
  })
end

local function message_rows(message)
  local rows = {}
  for i = 1, M.LYRIC_ROWS do
    rows[i] = {}
  end
  rows[MIDDLE] = { { LYRIC_ICON .. " " .. message, "EldenMusicLyricDim" } }
  return rows
end

-- the sung line between the skin's marks, lit up as far as the song has sung it
local function sung_segments(text, sweep, sung)
  local room = M.WIDTH - 2 - vim.fn.strdisplaywidth(sung[1] .. sung[2])
  if text == "" then
    -- the gaps between verses still show where the song is
    text, sweep = LYRIC_ICON, 0
  end
  text = M.fit(text, room)
  local lit = vim.fn.strcharpart(text, 0, math.floor(vim.fn.strchars(text) * sweep + 0.5))
  return {
    { sung[1], "EldenMusicLyricMark" },
    { lit, "EldenMusicLyricSweep" },
    { text:sub(#lit + 1), "EldenMusicLyric" },
    { sung[2], "EldenMusicLyricMark" },
  }
end

local function synced_rows(view)
  local rows, lines = {}, view.lyrics.lines
  for i = 1, M.LYRIC_ROWS do
    local index = view.focus + i - MIDDLE
    local distance = math.abs(i - MIDDLE)
    local text = lines[index] and lines[index].text or ""
    if distance == 0 then
      rows[i] = sung_segments(text, view.sweep or 0, view.style.sung)
    else
      rows[i] = { { M.fit(text, M.WIDTH - 2), DEPTH[math.min(distance, #DEPTH)] } }
    end
  end
  return rows
end

local function plain_rows(lines, top)
  local rows = {}
  for i = 1, M.LYRIC_ROWS do
    local line = lines[top + i - 1]
    rows[i] = { { M.fit(line and line.text or "", M.WIDTH - 2), "EldenMusicLyricPlain" } }
  end
  return rows
end

local function lyric_rows(view)
  local lyrics, words = view.lyrics, view.words
  if lyrics == nil then
    return message_rows(words.loading)
  end
  if lyrics == false then
    return message_rows(words.missing)
  end
  if lyrics.kind == "instrumental" then
    return message_rows(words.instrumental)
  end
  if lyrics.kind == "plain" then
    return plain_rows(lyrics.lines, view.focus)
  end
  return synced_rows(view)
end

--- Builds the lyrics: the sung line in the middle, its neighbors fading with distance, all centered.
---@param view { lyrics: table|false|nil, focus: integer, sweep: number|nil, style: table, words: table }
--- lyrics is nil while loading and false when none was found, focus is the sung line when synced
--- and the first shown line when plain, sweep how much of the sung line is sung
---@return { lines: string[], marks: table[] }
function M.lyrics_block(view)
  local block = { lines = {}, marks = {} }
  for i, segments in ipairs(lyric_rows(view)) do
    local width = width_of(segments)
    local row = width > 0 and segments_line(math.floor((M.WIDTH - width) / 2), segments)
      or { lines = { "" }, marks = {} }
    block.lines[i] = row.lines[1]
    for _, mark in ipairs(row.marks) do
      mark.row = i - 1
      table.insert(block.marks, mark)
    end
  end
  return block
end

--- Builds the keys row, spread evenly across the panel.
---@param track { playing: boolean }
---@return { lines: string[], marks: table[] }
function M.keys_row(track)
  local keys = {
    { "󰒮", "b" },
    { track.playing and "󰏤" or "󰐊", "p" },
    { "󰒭", "n" },
    { "↕", "j k" },
    { "󰅖", "q" },
  }
  local width = 0
  for _, key in ipairs(keys) do
    width = width + vim.fn.strdisplaywidth(key[1] .. " " .. key[2])
  end
  local gap = math.floor((M.WIDTH - width) / (#keys + 1))
  local segments = {}
  for i, key in ipairs(keys) do
    if i > 1 then
      table.insert(segments, { (" "):rep(gap) })
    end
    table.insert(segments, { key[1], "EldenMusicKeyIcon" })
    table.insert(segments, { " " .. key[2], "EldenMusicKeys" })
  end
  return segments_line(gap, segments)
end

--- Keeps the first plain line shown inside the lyrics, so scrolling stops at both ends.
---@param lyrics { lines: table[] }
---@param top integer
---@return integer
function M.clamp_scroll(lyrics, top)
  local last = math.max(1, #lyrics.lines - M.LYRIC_ROWS + 1)
  return math.min(math.max(top, 1), last)
end

local function place(layout, row, piece, marks)
  for i, line in ipairs(piece.lines) do
    layout.lines[row + i] = line
  end
  for _, mark in ipairs(piece.marks) do
    table.insert(marks, vim.tbl_extend("force", mark, { row = row + mark.row }))
  end
end

local function place_details(layout, track)
  local details = {
    { track.title, "EldenMusicTitle" },
    { track.artist, "EldenMusicArtist" },
    { track.album, "EldenMusicAlbum" },
  }
  for i, detail in ipairs(details) do
    place(
      layout,
      i - 1,
      segments_line(TEXT_COL, { { M.fit(detail[1], ROOM), detail[2] } }),
      layout.marks.static
    )
  end
end

--- Lays out the whole panel, with the marks of each moving piece kept apart.
---@param track { title: string, artist: string, album: string, playing: boolean, duration: number|nil }
---@param source string|nil "cider" or "music"
---@param view table as lyrics_block takes it, plus elapsed (seconds) and eq_ms
---@return { lines: string[], marks: { static: table[], state: table[], progress: table[], lyrics: table[] }, cover: table }
function M.panel(track, source, view)
  local layout = {
    lines = {},
    marks = { static = {}, state = {}, progress = {}, lyrics = {} },
    cover = M.COVER,
  }
  for row = 1, M.HEIGHT do
    layout.lines[row] = ""
  end
  local marks = layout.marks
  local divider = M.divider(view.style.divider)
  place_details(layout, track)
  place(layout, M.ROWS.state, M.state_row(track, source, view.eq_ms or 0), marks.state)
  place(
    layout,
    M.ROWS.progress,
    M.progress_row(view.elapsed, track.duration, view.style.bar),
    marks.progress
  )
  place(layout, M.ROWS.lyrics - 1, divider, marks.static)
  place(layout, M.ROWS.lyrics, M.lyrics_block(view), marks.lyrics)
  place(layout, M.ROWS.lyrics + M.LYRIC_ROWS, divider, marks.static)
  place(layout, M.HEIGHT - 1, M.keys_row(track), marks.static)
  return layout
end

return M
