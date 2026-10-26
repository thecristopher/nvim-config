-- The now playing panel's layout: the cover with the song, the equalizer and the progress beside it,
-- the lyrics between two dividers when they are shown, the keys last. Every piece that moves
-- (equalizer, progress, lyrics) builds on its own so the panel can redraw it alone. Pieces come back
-- as { lines, marks } with rows counted from the piece's first line. Pure logic only.
local M = {}

M.WIDTH = 52
M.LYRIC_ROWS = 5
-- terminal cells are about twice as tall as wide, so 16 by 8 reads as a square
M.COVER = { row = 0, col = 1, width = 16, height = 8 }
-- zero based rows of the pieces that move: the song leaves a row under the panel's title, the
-- equalizer stands on the progress bar and the bar closes at the cover's bottom edge
M.ROWS = { equalizer = 5, progress = 7, lyrics = M.COVER.height + 1 }

local TEXT_COL = M.COVER.col + M.COVER.width + 2
local ROOM = M.WIDTH - TEXT_COL - 1
local BARS = { "▁", "▂", "▃", "▄", "▅", "▆", "▇", "█" }
-- two rows of bars, so each one climbs through twice the levels a single block has
local EQ_LEVELS = #BARS * 2
-- one bar per two columns, a gap between each, across the whole room beside the cover
local EQ_BARS = math.floor((ROOM + 1) / 2)
local ALBUM_ICON = "󰀥"
local LYRIC_ICON = "󰝚"
local MIDDLE = math.ceil(M.LYRIC_ROWS / 2)
-- a sung line wraps to at most this many rows, so a neighbor always shows on each side
local SUNG_ROWS = M.LYRIC_ROWS - 2
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

--- Tells how tall the panel is, shorter when the lyrics are hidden.
---@param hide_lyrics boolean|nil
---@return integer rows
function M.height(hide_lyrics)
  local lyrics = hide_lyrics and 0 or M.LYRIC_ROWS + 1
  -- the cover, the divider under it, the lyrics with their closing divider, the keys
  return M.COVER.height + 1 + lyrics + 1
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
---@return integer[] heights from 1 to 16, one per bar
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
    -- the bass on the left stands taller, like a real spectrum
    local reach = 1 - 0.4 * (i - 1) / (EQ_BARS - 1)
    heights[i] = math.floor(wave * reach * (EQ_LEVELS - 1) + 0.5) + 1
  end
  return heights
end

--- Builds the two rows of the equalizer, the upper one only lit by the bars that reach it.
---@param track { playing: boolean }
---@param ms integer milliseconds the equalizer has been dancing
---@return { lines: string[], marks: table[] }
function M.equalizer_rows(track, ms)
  local upper, lower = {}, {}
  for i, height in ipairs(M.equalizer(ms, track.playing)) do
    if i > 1 then
      table.insert(upper, { " " })
      table.insert(lower, { " " })
    end
    table.insert(upper, { height > #BARS and BARS[height - #BARS] or " ", "EldenMusicEqHigh" })
    table.insert(lower, { BARS[math.min(height, #BARS)], "EldenMusicEqLow" })
  end
  local top, bottom = segments_line(TEXT_COL, upper), segments_line(TEXT_COL, lower)
  for _, mark in ipairs(bottom.marks) do
    mark.row = 1
    table.insert(top.marks, mark)
  end
  return { lines = { top.lines[1], bottom.lines[1] }, marks = top.marks }
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

-- cuts a word wider than the row into pieces that fit
local function split_word(word, width)
  local pieces = {}
  while vim.fn.strdisplaywidth(word) > width do
    table.insert(pieces, vim.fn.strcharpart(word, 0, width))
    word = vim.fn.strcharpart(word, width)
  end
  table.insert(pieces, word)
  return pieces
end

--- Splits text into rows that fit a width, breaking between words when it can.
---@param text string
---@param width integer
---@return string[] at least one row, empty when the text is
function M.wrap(text, width)
  local rows, row = {}, ""
  for word in text:gmatch("%S+") do
    for _, piece in ipairs(split_word(word, width)) do
      local joined = row == "" and piece or row .. " " .. piece
      if vim.fn.strdisplaywidth(joined) <= width then
        row = joined
      else
        table.insert(rows, row)
        row = piece
      end
    end
  end
  table.insert(rows, row)
  return rows
end

local function reversed(list)
  local flipped = {}
  for i = #list, 1, -1 do
    table.insert(flipped, list[i])
  end
  return flipped
end

-- the sung line between the skin's marks on every row it wraps to, lit up as far as it is sung
local function sung_rows(text, sweep, sung)
  local room = M.WIDTH - 2 - vim.fn.strdisplaywidth(sung[1] .. sung[2])
  if text == "" then
    -- the gaps between verses still show where the song is
    text, sweep = LYRIC_ICON, 0
  end
  local chunks = M.wrap(text, room)
  if #chunks > SUNG_ROWS then
    local rest = table.concat(vim.list_slice(chunks, SUNG_ROWS), " ")
    chunks = vim.list_slice(chunks, 1, SUNG_ROWS)
    chunks[SUNG_ROWS] = M.fit(rest, room)
  end
  local total = 0
  for _, chunk in ipairs(chunks) do
    total = total + vim.fn.strchars(chunk)
  end
  local to_light = math.floor(total * sweep + 0.5)
  local rows = {}
  for i = 1, #chunks do
    local chunk = chunks[i]
    local lit = vim.fn.strcharpart(chunk, 0, to_light)
    to_light = math.max(0, to_light - vim.fn.strchars(chunk))
    rows[i] = {
      { sung[1], "EldenMusicLyricMark" },
      { lit, "EldenMusicLyricSweep" },
      { chunk:sub(#lit + 1), "EldenMusicLyric" },
      { sung[2], "EldenMusicLyricMark" },
    }
  end
  return rows
end

-- fills room rows with the lines from start on, walking up (step -1) or down (step 1). A line that
-- fits shows whole, one that does not shows cut on a single row, never as a stray piece of itself
local function neighbor_rows(lines, start, step, room, group_of)
  local rows, index = {}, start
  while #rows < room do
    local line = lines[index]
    local chunks = line and M.wrap(line.text, M.WIDTH - 2) or { "" }
    if #chunks > room - #rows then
      chunks = { M.fit(line.text, M.WIDTH - 2) }
    end
    -- walking up, the closest rows are the end of the line above
    if step < 0 then
      chunks = reversed(chunks)
    end
    for _, chunk in ipairs(chunks) do
      table.insert(rows, { { chunk, group_of(index) } })
    end
    index = index + step
  end
  return step < 0 and reversed(rows) or rows
end

local function synced_rows(view)
  local lines, focus = view.lyrics.lines, view.focus
  local text = lines[focus] and lines[focus].text or ""
  local sung = sung_rows(text, view.sweep or 0, view.style.sung)
  local function depth(index)
    return DEPTH[math.min(math.abs(index - focus), #DEPTH)]
  end
  -- the neighbors share what the sung line leaves, the odd row goes to what comes next
  local free = M.LYRIC_ROWS - #sung
  local above = math.floor(free / 2)
  local below = free - above
  local rows = neighbor_rows(lines, focus - 1, -1, above, depth)
  vim.list_extend(rows, sung)
  vim.list_extend(rows, neighbor_rows(lines, focus + 1, 1, below, depth))
  return rows
end

local function plain_rows(lines, top)
  return neighbor_rows(lines, top, 1, M.LYRIC_ROWS, function()
    return "EldenMusicLyricPlain"
  end)
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
    { "󰝚", "l" },
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
    { { M.fit(track.title, ROOM), "EldenMusicTitle" } },
    { { M.fit(track.artist, ROOM), "EldenMusicArtist" } },
  }
  -- a single without an album keeps its row empty instead of a lonely icon
  if track.album ~= "" then
    table.insert(details, {
      { ALBUM_ICON .. " ", "EldenMusicAlbumIcon" },
      { M.fit(track.album, ROOM - 2), "EldenMusicAlbum" },
    })
  end
  for i, segments in ipairs(details) do
    place(layout, i, segments_line(TEXT_COL, segments), layout.marks.static)
  end
end

--- Lays out the whole panel, with the marks of each moving piece kept apart.
---@param track { title: string, artist: string, album: string, playing: boolean, duration: number|nil }
---@param view table as lyrics_block takes it, plus elapsed (seconds), eq_ms and hide_lyrics
---@return { lines: string[], marks: { static: table[], equalizer: table[], progress: table[], lyrics: table[] }, cover: table }
function M.panel(track, view)
  local height = M.height(view.hide_lyrics)
  local layout = {
    lines = {},
    marks = { static = {}, equalizer = {}, progress = {}, lyrics = {} },
    cover = M.COVER,
  }
  for row = 1, height do
    layout.lines[row] = ""
  end
  local marks = layout.marks
  local divider = M.divider(view.style.divider)
  place_details(layout, track)
  place(layout, M.ROWS.equalizer, M.equalizer_rows(track, view.eq_ms or 0), marks.equalizer)
  place(
    layout,
    M.ROWS.progress,
    M.progress_row(view.elapsed, track.duration, view.style.bar),
    marks.progress
  )
  place(layout, M.ROWS.lyrics - 1, divider, marks.static)
  if not view.hide_lyrics then
    place(layout, M.ROWS.lyrics, M.lyrics_block(view), marks.lyrics)
    place(layout, M.ROWS.lyrics + M.LYRIC_ROWS, divider, marks.static)
  end
  place(layout, height - 1, M.keys_row(track), marks.static)
  return layout
end

return M
