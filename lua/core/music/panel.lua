-- The now playing panel: a float above the statusline's corner with the album cover, the song,
-- and keys for play/pause, next and previous. It closes as soon as focus leaves it.
local actions = require("core.music.actions")
local cover   = require("core.music.cover")

local M = {}

local ns = vim.api.nvim_create_namespace("eldentree_music_panel")
local current

local function define_highlights()
  local p = require("core.themes").palette()
  vim.api.nvim_set_hl(0, "EldenMusicTitle",  { fg = p.yellow, bold = true })
  vim.api.nvim_set_hl(0, "EldenMusicArtist", { fg = p.text })
  vim.api.nvim_set_hl(0, "EldenMusicAlbum",  { fg = p.subtext0, italic = true })
  vim.api.nvim_set_hl(0, "EldenMusicState",  { fg = p.mauve })
  vim.api.nvim_set_hl(0, "EldenMusicKeys",   { fg = p.overlay2 })
end

--- Tells whether the panel is on screen.
---@return boolean
function M.is_open()
  return current ~= nil and vim.api.nvim_win_is_valid(current.win)
end

--- Closes the panel and its cover.
function M.close()
  if not current then return end
  local win = current.win
  current = nil
  require("core.hud.portrait").close()
  pcall(vim.api.nvim_win_close, win, true)
end

local function draw(track, source)
  local layout = actions.panel(track, source)
  local buf = current.buf
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, layout.lines)
  vim.bo[buf].modifiable = false
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for _, mark in ipairs(layout.marks) do
    vim.api.nvim_buf_set_extmark(buf, ns, mark.row, mark.col, {
      end_row = mark.row, end_col = #layout.lines[mark.row + 1], hl_group = mark.group,
    })
  end

  local shown = current
  cover.fetch(track, source, function(file)
    -- the song may have changed or the panel closed while the cover was on its way
    if not file or current ~= shown or shown.track ~= track then return end
    require("core.hud.portrait").show(shown.win, file, layout.cover)
  end)
end

local function map_keys(buf)
  local music = require("core.music")
  local function map(lhs, fn, desc) vim.keymap.set("n", lhs, fn, { buffer = buf, nowait = true, desc = desc }) end
  map("p", function() music.control("playpause") end, "Play or pause")
  map("n", function() music.control("next") end, "Next song")
  map("b", function() music.control("previous") end, "Previous song")
  map("q", M.close, "Close")
  map("<Esc>", M.close, "Close")
end

local function open_window(buf, height)
  return vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    row = vim.o.lines - height - vim.o.cmdheight - 3,
    col = vim.o.columns - actions.PANEL_WIDTH - 2,
    width = actions.PANEL_WIDTH, height = height,
    style = "minimal", border = require("core.skin").border(),
    title = require("core.skin").title(" Now playing "), title_pos = "center",
    -- the cover float sits at 45, so the panel stays under it
    zindex = 40,
  })
end

--- Redraws the panel for a new song or state, if it is open.
---@param track table|nil
---@param source string|nil
function M.update(track, source)
  if not M.is_open() then return end
  if not track then return M.close() end
  current.track = track
  draw(track, source)
end

--- Opens the panel for a track, focused so its keys work right away.
---@param track table
---@param source string|nil "cider" or "music"
function M.open(track, source)
  if M.is_open() then return vim.api.nvim_set_current_win(current.win) end
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  current = { buf = buf, track = track }
  current.win = open_window(buf, #actions.panel(track, source).lines)
  map_keys(buf)
  vim.api.nvim_create_autocmd("WinLeave", { buffer = buf, once = true, callback = M.close })
  draw(track, source)
end

function M.setup()
  define_highlights()
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("eldentree_music_panel", { clear = true }),
    callback = define_highlights,
  })
end

return M
