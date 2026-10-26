-- The now playing panel: a float above the statusline's corner with the album cover, the song, an
-- equalizer, the progress bar and the lyrics following the music, dressed by the franchise's skin.
-- Each moving piece redraws alone in its own namespace. It closes as soon as focus leaves it.
local layout = require("core.music.actions.panel")
local lyric_actions = require("core.music.actions.lyrics")
local cover = require("core.music.cover")
local lyrics = require("core.music.lyrics")

local M = {}

-- quick enough for the karaoke sweep to glide, it only repaints when something moved
local FOLLOW_MS = 100
local EQ_MS = 120
local PIECES = { "static", "state", "progress", "lyrics" }

local namespaces = {}
for _, piece in ipairs(PIECES) do
  namespaces[piece] = vim.api.nvim_create_namespace("eldentree_music_" .. piece)
end

local current
local sung_line, far_line = {}, {}

local function define_highlights()
  local p = require("core.themes").palette()
  local groups = {
    EldenMusicTitle = { fg = p.yellow, bold = true },
    EldenMusicArtist = { fg = p.text },
    EldenMusicAlbum = { fg = p.subtext0, italic = true },
    EldenMusicState = { fg = p.mauve },
    EldenMusicKeys = { fg = p.overlay1 },
    EldenMusicKeyIcon = { fg = p.peach },
    EldenMusicEqLow = { fg = p.mauve },
    EldenMusicEqHigh = { fg = p.yellow },
    EldenMusicTime = { fg = p.subtext0 },
    EldenMusicBarDone = { fg = p.yellow },
    EldenMusicBarHead = { fg = p.peach, bold = true },
    EldenMusicBarLeft = { fg = p.surface2 },
    EldenMusicDivider = { fg = p.overlay0 },
    EldenMusicDividerGem = { fg = p.yellow },
    EldenMusicLyric = { fg = p.text, bold = true },
    EldenMusicLyricSweep = { fg = p.yellow, bold = true },
    EldenMusicLyricMark = { fg = p.peach },
    EldenMusicLyricNear = { fg = p.overlay2 },
    EldenMusicLyricFar = { fg = p.surface2 },
    EldenMusicLyricPlain = { fg = p.subtext1 },
    EldenMusicLyricDim = { fg = p.overlay1 },
  }
  for name, attrs in pairs(groups) do
    vim.api.nvim_set_hl(0, name, attrs)
  end
  sung_line, far_line = groups.EldenMusicLyric, groups.EldenMusicLyricFar
end

--- Tells whether the panel is on screen.
---@return boolean
function M.is_open()
  return current ~= nil and vim.api.nvim_win_is_valid(current.win)
end

--- Closes the panel, its cover and its animations.
function M.close()
  if not current then
    return
  end
  local closing = current
  current = nil
  if closing.timer then
    closing.timer:stop()
    closing.timer:close()
  end
  if closing.equalizer then
    closing.equalizer:stop()
  end
  require("core.hud.portrait").close("music")
  pcall(vim.api.nvim_win_close, closing.win, true)
end

local function view()
  return {
    lyrics = current.lyrics,
    focus = current.focus,
    sweep = current.sweep,
    elapsed = current.elapsed,
    eq_ms = current.eq_ms,
    style = current.style,
    words = current.words,
  }
end

local function write_lines(first, last, lines)
  local buf = current.buf
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, first, last, false, lines)
  vim.bo[buf].modifiable = false
end

local function paint(piece, marks, offset)
  local namespace = namespaces[piece]
  vim.api.nvim_buf_clear_namespace(current.buf, namespace, 0, -1)
  for _, mark in ipairs(marks) do
    local row = offset + mark.row
    vim.api.nvim_buf_set_extmark(current.buf, namespace, row, mark.col, {
      end_row = row,
      end_col = mark.end_col,
      hl_group = mark.group,
    })
  end
end

-- what a piece looks like, so a tick that changed nothing repaints nothing
local function signature(built)
  local parts = { table.concat(built.lines, "\n") }
  for _, mark in ipairs(built.marks) do
    table.insert(parts, ("%d:%d:%d:%s"):format(mark.row, mark.col, mark.end_col, mark.group))
  end
  return table.concat(parts, "|")
end

local function draw_piece(piece, row, built)
  local drawn = signature(built)
  if current.drawn[piece] == drawn then
    return
  end
  current.drawn[piece] = drawn
  write_lines(row, row + #built.lines, built.lines)
  paint(piece, built.marks, row)
end

local function draw_state()
  draw_piece(
    "state",
    layout.ROWS.state,
    layout.state_row(current.track, current.source, current.eq_ms)
  )
end

local function draw_progress()
  draw_piece(
    "progress",
    layout.ROWS.progress,
    layout.progress_row(current.elapsed, current.track.duration, current.style.bar)
  )
end

local function draw_lyrics()
  draw_piece("lyrics", layout.ROWS.lyrics, layout.lyrics_block(view()))
end

local function light_up_sung_line()
  vim.api.nvim_set_hl(0, "EldenMusicLyric", far_line)
  require("core.motion").fade_hl("EldenMusicLyric", sung_line, { duration = 280 })
end

local function follow_lyrics()
  local found = current.lyrics
  if type(found) ~= "table" or found.kind ~= "synced" or not current.elapsed then
    return
  end
  local focus = lyric_actions.line_at(found.lines, current.elapsed)
  local moved = focus ~= current.focus
  current.focus = focus
  current.sweep = lyric_actions.sung(found.lines, focus, current.elapsed, current.track.duration)
  draw_lyrics()
  if moved then
    light_up_sung_line()
  end
end

local function follow()
  if not M.is_open() then
    return
  end
  current.elapsed = require("core.music").elapsed()
  draw_progress()
  follow_lyrics()
end

-- forgets the last song's lyrics, telling whether the song changed
local function reset_lyrics(track)
  local name = lyric_actions.name(track)
  if current.lyrics_for == name then
    return false
  end
  current.lyrics_for, current.lyrics, current.focus, current.sweep = name, nil, 0, 0
  return true
end

local function load_lyrics(track)
  local shown, name = current, current.lyrics_for
  lyrics.fetch(track, function(found)
    -- the song may have changed or the panel closed while LRCLIB answered
    if current ~= shown or shown.lyrics_for ~= name then
      return
    end
    shown.lyrics = found
    shown.focus = type(found) == "table" and found.kind == "plain" and 1 or 0
    draw_lyrics()
    follow()
  end)
end

local function draw(track, source)
  local song_changed = reset_lyrics(track)
  current.elapsed = require("core.music").elapsed()
  local built = layout.panel(track, source, view())
  write_lines(0, -1, built.lines)
  current.drawn = {}
  for _, piece in ipairs(PIECES) do
    paint(piece, built.marks[piece], 0)
  end
  if song_changed then
    load_lyrics(track)
  end

  local shown = current
  cover.fetch(track, source, function(file)
    -- the song may have changed or the panel closed while the cover was on its way
    if not file or current ~= shown or shown.track ~= track then
      return
    end
    require("core.hud.portrait").show(shown.win, file, built.cover, "music")
  end)
end

-- only plain lyrics scroll, synced ones follow the song on their own
local function scroll(step)
  if type(current.lyrics) ~= "table" or current.lyrics.kind ~= "plain" then
    return
  end
  current.focus = layout.clamp_scroll(current.lyrics, current.focus + step)
  draw_lyrics()
end

local function map_keys(buf)
  local music = require("core.music")
  local function map(lhs, fn, desc)
    vim.keymap.set("n", lhs, fn, { buffer = buf, nowait = true, desc = desc })
  end
  map("p", function()
    music.control("playpause")
  end, "Play or pause")
  map("n", function()
    music.control("next")
  end, "Next song")
  map("b", function()
    music.control("previous")
  end, "Previous song")
  map("j", function()
    scroll(1)
  end, "Scroll the lyrics down")
  map("k", function()
    scroll(-1)
  end, "Scroll the lyrics up")
  map("q", M.close, "Close")
  map("<Esc>", M.close, "Close")
end

local function open_window(buf)
  local skin = require("core.skin")
  return vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    row = math.max(0, vim.o.lines - layout.HEIGHT - vim.o.cmdheight - 3),
    col = math.max(0, vim.o.columns - layout.WIDTH - 2),
    width = layout.WIDTH,
    height = layout.HEIGHT,
    style = "minimal",
    border = skin.border(),
    title = skin.title(" " .. current.words.title .. " "),
    title_pos = "center",
    -- the cover float sits at 45, so the panel stays under it
    zindex = 40,
  })
end

local function start_animations()
  current.timer = vim.uv.new_timer()
  current.timer:start(FOLLOW_MS, FOLLOW_MS, vim.schedule_wrap(follow))
  -- the equalizer is pure decoration, so it rides the motion loop and stills with <leader>um
  local shown = current
  current.equalizer = require("core.motion").loop({
    interval = EQ_MS,
    on_tick = function(ms)
      if current ~= shown then
        return false
      end
      current.eq_ms = ms
      draw_state()
    end,
  })
end

--- Redraws the panel for a new song or state, if it is open.
---@param track table|nil
---@param source string|nil
function M.update(track, source)
  if not M.is_open() then
    return
  end
  if not track then
    return M.close()
  end
  current.track, current.source = track, source
  draw(track, source)
end

--- Opens the panel for a track, focused so its keys work right away.
---@param track table
---@param source string|nil "cider" or "music"
function M.open(track, source)
  if M.is_open() then
    return vim.api.nvim_set_current_win(current.win)
  end
  local lore = require("core.franchise").current()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  current = {
    buf = buf,
    track = track,
    source = source,
    eq_ms = 0,
    drawn = {},
    style = lore.skin.music,
    words = lore.music,
  }
  current.win = open_window(buf)
  map_keys(buf)
  vim.api.nvim_create_autocmd("WinLeave", { buffer = buf, once = true, callback = M.close })
  draw(track, source)
  start_animations()
end

function M.setup()
  define_highlights()
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("eldentree_music_panel", { clear = true }),
    callback = define_highlights,
  })
end

return M
