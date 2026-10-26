-- The now playing panel: a float above the statusline's corner with the album cover, the song, an
-- equalizer, the progress bar and the lyrics following the music, dressed by the franchise's skin.
-- `l` shows or hides the lyrics, `vim.g.eldentree_lyrics = false` starts with them hidden. Each
-- moving piece redraws alone in its own namespace. It closes as soon as focus leaves it.
local layout = require("core.music.actions.panel")
local lyric_actions = require("core.music.actions.lyrics")
local cover = require("core.music.cover")
local lyrics = require("core.music.lyrics")

local M = {}

-- quick enough for the karaoke sweep to glide, it only repaints when something moved
local FOLLOW_MS = 100
local EQ_MS = 120
local PIECES = { "static", "equalizer", "progress", "lyrics" }

local namespaces = {}
for _, piece in ipairs(PIECES) do
  namespaces[piece] = vim.api.nvim_create_namespace("eldentree_music_" .. piece)
end

local current
local sung_line, far_line = {}, {}
-- the choice made with l holds for the session, the setting only picks how it starts
local lyrics_shown

local function showing_lyrics()
  if lyrics_shown == nil then
    lyrics_shown = vim.g.eldentree_lyrics ~= false
  end
  return lyrics_shown
end

local function define_highlights()
  local p = require("core.themes").palette()
  local groups = {
    EldenMusicTitle = { fg = p.yellow, bold = true },
    EldenMusicArtist = { fg = p.text, bold = true },
    EldenMusicAlbum = { fg = p.subtext1, italic = true },
    EldenMusicAlbumIcon = { fg = p.peach },
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
    hide_lyrics = not showing_lyrics(),
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

local function draw_equalizer()
  draw_piece(
    "equalizer",
    layout.ROWS.equalizer,
    layout.equalizer_rows(current.track, current.eq_ms)
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
  if not showing_lyrics() then
    return
  end
  draw_piece("lyrics", layout.ROWS.lyrics, layout.lyrics_block(view()))
end

local function light_up_sung_line()
  vim.api.nvim_set_hl(0, "EldenMusicLyric", far_line)
  require("core.motion").fade_hl("EldenMusicLyric", sung_line, { duration = 280 })
end

local function follow_lyrics()
  local found = current.lyrics
  if not showing_lyrics() or not current.elapsed then
    return
  end
  if type(found) ~= "table" or found.kind ~= "synced" then
    return
  end
  local at = current.elapsed + lyric_actions.LEAD_SECONDS
  local focus = lyric_actions.line_at(found.lines, at)
  local moved = focus ~= current.focus
  current.focus = focus
  current.sweep = lyric_actions.sung(found.lines, focus, at, current.track.duration)
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
  shown.fetching = true
  lyrics.fetch(track, function(found)
    -- the song may have changed or the panel closed while LRCLIB answered
    if current ~= shown or shown.lyrics_for ~= name then
      return
    end
    shown.fetching = false
    shown.lyrics = found
    shown.focus = type(found) == "table" and found.kind == "plain" and 1 or 0
    draw_lyrics()
    follow()
  end)
end

local function draw(track, source)
  local song_changed = reset_lyrics(track)
  current.elapsed = require("core.music").elapsed()
  local built = layout.panel(track, view())
  write_lines(0, -1, built.lines)
  current.drawn = {}
  for _, piece in ipairs(PIECES) do
    paint(piece, built.marks[piece], 0)
  end
  if song_changed then
    current.fetching = false
  end
  if showing_lyrics() and current.lyrics == nil and not current.fetching then
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
  map("l", M.toggle_lyrics, "Show or hide the lyrics")
  map("q", M.close, "Close")
  map("<Esc>", M.close, "Close")
end

-- where the panel sits and how tall it is, it grows upward from the statusline's corner
local function placement()
  local height = layout.height(not showing_lyrics())
  return {
    relative = "editor",
    row = math.max(0, vim.o.lines - height - vim.o.cmdheight - 3),
    col = math.max(0, vim.o.columns - layout.WIDTH - 2),
    width = layout.WIDTH,
    height = height,
  }
end

local function open_window(buf)
  local skin = require("core.skin")
  return vim.api.nvim_open_win(
    buf,
    true,
    vim.tbl_extend("force", placement(), {
      style = "minimal",
      border = skin.border(),
      title = skin.title(" " .. current.words.title .. " "),
      title_pos = "center",
      -- the cover float sits at 45, so the panel stays under it
      zindex = 40,
    })
  )
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
      draw_equalizer()
    end,
  })
end

--- Shows the lyrics under the song or hides them, resizing the panel around the change.
function M.toggle_lyrics()
  lyrics_shown = not showing_lyrics()
  if not M.is_open() then
    return
  end
  vim.api.nvim_win_set_config(current.win, placement())
  -- the panel moved, so the cover is placed anew instead of left where the panel was
  require("core.hud.portrait").close("music")
  draw(current.track, current.source)
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
