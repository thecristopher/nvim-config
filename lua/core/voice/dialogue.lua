-- The box a character speaks in: one float centered at the bottom, right above the statusline,
-- with their name on the frame. Notifications keep the top right, so what a character says and
-- what the editor reports never share a stack. A new line replaces the one on screen, except a
-- written line arriving while a voice is speaking: it waits for the voice to end.
local actions = require("core.voice.actions")

local M = {}

-- the box on screen, how many lines it has shown (so a line's hide never takes a newer one) and
-- whether a voice is saying the one on screen
local shown = { win = nil, buf = nil, said = 0, speaking = false }

-- the written line waiting for the voice on screen to end, only the latest one
local waiting = nil

-- under the banners and the sprite, over the code and the drift
local ZINDEX = 200

local function scratch()
  if shown.buf and vim.api.nvim_buf_is_valid(shown.buf) then
    return shown.buf
  end
  shown.buf = vim.api.nvim_create_buf(false, true)
  vim.bo[shown.buf].bufhidden = "hide"
  return shown.buf
end

local function bottom_rows()
  return vim.o.cmdheight + (vim.o.laststatus > 0 and 1 or 0)
end

local function window_config(place, character)
  local skin = require("core.skin")
  return {
    relative = "editor",
    row = place.row,
    col = place.col,
    width = place.width,
    height = place.height,
    style = "minimal",
    border = skin.border(),
    title = character and (" " .. skin.title(character) .. " ") or nil,
    title_pos = character and "center" or nil,
    focusable = false,
    mouse = false,
    zindex = ZINDEX,
    noautocmd = true,
  }
end

--- Takes the line on screen away, if any.
function M.hide()
  if shown.win and vim.api.nvim_win_is_valid(shown.win) then
    pcall(vim.api.nvim_win_close, shown.win, true)
  end
  shown.win = nil
  shown.speaking = false
end

-- puts a line in the box and returns the function that takes that one line away
local function open(character, line, speaking)
  local place = actions.dialogue_place(line, character, vim.o.columns, vim.o.lines, bottom_rows())
  local buf = scratch()
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, place.lines)
  local config = window_config(place, character)
  if shown.win and vim.api.nvim_win_is_valid(shown.win) then
    config.noautocmd = nil
    vim.api.nvim_win_set_config(shown.win, config)
  else
    shown.win = vim.api.nvim_open_win(buf, false, config)
  end
  shown.said = shown.said + 1
  shown.speaking = speaking
  local said = shown.said
  return function()
    if shown.said == said then
      M.hide()
    end
  end
end

local function write_now(character, line)
  vim.defer_fn(open(character, line, false), actions.reading_ms(line))
end

---Shows a written line in the dialogue box for as long as it takes to read it. While a voice is
---speaking it waits for the voice to end instead of cutting it.
---@param character string|nil who says it, their name goes on the frame
---@param line string what they say
function M.write(character, line)
  if shown.speaking then
    waiting = { character = character, line = line }
    return
  end
  write_now(character, line)
end

---Shows a spoken line in the dialogue box, replacing the line on screen, until the returned
---function says the voice is over. A written line that waited for it shows right after.
---@param character string|nil who says it, their name goes on the frame
---@param line string what they say
---@return fun() done takes this line away, and does nothing once a newer one replaced it
function M.speak(character, line)
  local hide = open(character, line, true)
  return function()
    local current = shown.speaking
    hide()
    local next_line = waiting
    if current and not shown.speaking and next_line then
      waiting = nil
      write_now(next_line.character, next_line.line)
    end
  end
end

return M
