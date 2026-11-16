-- The album's tint: the panel's accents and the statusline's song take the cover's dominant vivid
-- color while that album plays, and go back to the region's palette when nothing plays or the
-- cover has none. The colors ImageMagick finds are kept per album next to the cover.
local actions = require("core.music.actions.tint")

local M = {}

-- the album whose colors dress the groups right now, nil while the palette does
local tinted_for
-- the album asked for last, so a late answer for an older one is dropped
local wanted

local function palette()
  return require("core.themes").palette()
end

local function binary()
  for _, name in ipairs({ "magick", "convert" }) do
    if vim.fn.executable(name) == 1 then
      return name
    end
  end
  return nil
end

local function cache_file(cover)
  return (cover:gsub("%.%w+$", "")) .. ".tint.json"
end

local function read_cache(file)
  local ok, lines = pcall(vim.fn.readfile, file)
  if not ok then
    return nil
  end
  local decoded_ok, colors = pcall(vim.json.decode, table.concat(lines, "\n"))
  return decoded_ok and type(colors) == "table" and colors or nil
end

local function set_groups(groups, fade)
  local motion = require("core.motion")
  for name, attrs in pairs(groups) do
    if fade then
      motion.fade_hl(name, attrs, { duration = 400 })
    else
      vim.api.nvim_set_hl(0, name, attrs)
    end
  end
end

--- Puts the region's colors back on every music group.
---@param fade? boolean fades instead of switching at once
function M.reset(fade)
  tinted_for = nil
  set_groups(actions.palette_groups(palette()), fade)
end

local function apply(album, colors)
  if album ~= wanted then
    return
  end
  local accent = actions.accent(colors, palette().base)
  if not accent then
    if tinted_for then
      M.reset(true)
    end
    return
  end
  tinted_for = album
  set_groups(actions.groups(accent), true)
  require("core.utils").refresh_statusline()
end

local function measure(album, cover)
  local cached = read_cache(cache_file(cover))
  if cached then
    return apply(album, cached)
  end
  local magick = binary()
  if not magick then
    return
  end
  vim.system(
    actions.command(magick, cover),
    { text = true },
    vim.schedule_wrap(function(result)
      local colors = result.code == 0 and actions.parse_histogram(result.stdout) or {}
      require("core.utils").write_state(cache_file(cover), { vim.json.encode(colors) })
      apply(album, colors)
    end)
  )
end

--- Tints the music groups after a track's album, or puts the palette back when nothing plays.
---@param track table|nil
---@param source string|nil "cider" or "music"
function M.follow(track, source)
  if not track then
    wanted = nil
    if tinted_for then
      M.reset(true)
    end
    return
  end
  local album = require("core.music.actions").cover_name(track)
  if album == wanted then
    return
  end
  wanted = album
  require("core.music.cover").fetch(track, source, function(file)
    if file then
      measure(album, file)
    end
  end)
end

-- a new region brings a new base, so the album is measured again against it
local function repaint()
  local album = tinted_for
  M.reset(false)
  local track, source = require("core.music").now_playing()
  if album and track then
    wanted = nil
    M.follow(track, source)
  end
end

function M.setup()
  M.reset(false)
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("eldentree_music_tint", { clear = true }),
    callback = repaint,
  })
end

return M
