-- The region's weather past the end of the buffer: when prose (markdown, text, a commit message) or
-- an empty buffer ends before its window does, embers, petals or rain drift through the empty rows
-- under it, the same sky core/hub draws on the HUD. Code stays calm. It lives in one borderless float
-- that takes no focus and lets every click through, only over the current window in normal mode,
-- and it sleeps with core/motion. `vim.g.eldentree_drift = false` turns it off.
local actions = require("core.drift.actions")
local hub = require("core.hub.actions")

local M = {}

local ns = vim.api.nvim_create_namespace("eldentree_drift")
local TICK_MS = 80

-- the float, the window it sits over, where it sits and its particles
local sky = { win = nil, buf = nil, target = nil, place = nil, embers = {}, loop = nil, at = 0 }

local function enabled()
  return vim.g.eldentree_drift ~= false and not vim.g.vscode and require("core.motion").enabled()
end

local function resting()
  local ok, rest = pcall(require, "core.rest")
  return ok and type(rest.resting) == "function" and rest.resting()
end

local function weather()
  return require("core.season").weather() or hub.weather(require("core.themes").current().name)
end

--- Clears the sky away until the next update finds room for it.
function M.hide()
  if sky.loop then
    sky.loop:stop()
    sky.loop = nil
  end
  if sky.win and vim.api.nvim_win_is_valid(sky.win) then
    pcall(vim.api.nvim_win_close, sky.win, true)
  end
  sky.win, sky.target, sky.place, sky.embers = nil, nil, nil, {}
end

-- only a window whose last line is on screen can have rows under its text, so a long file never
-- measures the height of lines nobody sees
local function text_rows(win, buf)
  if vim.fn.line("w$", win) < vim.api.nvim_buf_line_count(buf) then
    return nil
  end
  local ok, used =
    pcall(vim.api.nvim_win_text_height, win, { start_row = vim.fn.line("w0", win) - 1 })
  return ok and used.all or nil
end

-- a buffer with no name and nothing typed in it yet, the blank page
local function empty(buf)
  return vim.api.nvim_buf_get_name(buf) == ""
    and vim.api.nvim_buf_line_count(buf) == 1
    and vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == ""
end

local function placement_for(win)
  local buf = vim.api.nvim_win_get_buf(win)
  local drifts = actions.should_drift({
    enabled = enabled(),
    buftype = vim.bo[buf].buftype,
    filetype = vim.bo[buf].filetype,
    empty = empty(buf),
    diff = vim.wo[win].diff,
    floating = vim.api.nvim_win_get_config(win).relative ~= "",
    mode = vim.api.nvim_get_mode().mode,
    resting = resting(),
  })
  local rows = drifts and text_rows(win, buf)
  if not rows then
    return nil
  end
  local info = vim.fn.getwininfo(win)[1]
  local room = info and actions.sky(rows, info.height)
  return room and actions.placement(info, room)
end

local function scratch()
  if sky.buf and vim.api.nvim_buf_is_valid(sky.buf) then
    return sky.buf
  end
  sky.buf = vim.api.nvim_create_buf(false, true)
  vim.bo[sky.buf].bufhidden = "hide"
  return sky.buf
end

local function open_float(place)
  local config = vim.tbl_extend("force", place, {
    relative = "editor",
    style = "minimal",
    -- winborder would frame it, and the top edge would land on the file's last line
    border = "none",
    focusable = false,
    -- clicks land on the window under it, as if the sky were not there
    mouse = false,
    zindex = 1,
    noautocmd = true,
  })
  local ok, win = pcall(vim.api.nvim_open_win, scratch(), false, config)
  if not ok then
    return nil
  end
  vim.wo[win].winhighlight = "Normal:Normal,EndOfBuffer:EndOfBuffer"
  vim.wo[win].winblend = 0
  return win
end

local function place_float(place)
  local lines = {}
  for index = 1, place.height do
    lines[index] = ""
  end
  vim.api.nvim_buf_set_lines(scratch(), 0, -1, false, lines)
  if sky.win and vim.api.nvim_win_is_valid(sky.win) then
    vim.api.nvim_win_set_config(sky.win, {
      relative = "editor",
      row = place.row,
      col = place.col,
      width = place.width,
      height = place.height,
    })
    return
  end
  sky.win = open_float(place)
end

local function draw(dt)
  local place = sky.place
  local current = weather()
  local alive = {}
  for _, ember in ipairs(sky.embers) do
    hub.step_ember(ember, dt)
    if hub.ember_alive(ember) then
      table.insert(alive, ember)
    end
  end
  local budget = actions.budget(hub.ember_budget(place.width, place.height))
  while #alive < budget and math.random() < 0.3 do
    table.insert(alive, hub.spawn_ember(math.random, place.width, place.height, current))
  end
  sky.embers = alive

  vim.api.nvim_buf_clear_namespace(sky.buf, ns, 0, -1)
  for _, ember in ipairs(alive) do
    local row, col = math.floor(ember.y), math.floor(ember.x)
    if row >= 0 and row < place.height and col >= 0 and col < place.width then
      local glyph, level = hub.ember_look(ember, current)
      vim.api.nvim_buf_set_extmark(sky.buf, ns, row, 0, {
        virt_text = { { glyph, "EldenEmber" .. level } },
        virt_text_win_col = col,
        priority = 100,
      })
    end
  end
end

local function start_loop()
  if sky.loop and sky.loop:running() then
    return
  end
  sky.at = 0
  sky.loop = require("core.motion").loop({
    interval = TICK_MS,
    on_tick = function(elapsed)
      if not sky.win or not vim.api.nvim_win_is_valid(sky.win) or not sky.place then
        return false
      end
      draw(elapsed - sky.at)
      sky.at = elapsed
    end,
  })
end

--- Places the sky under the current window's text, or clears it when there is no room for it.
function M.update()
  local win = vim.api.nvim_get_current_win()
  local place = placement_for(win)
  if not place then
    return M.hide()
  end
  local moved = sky.target ~= win or not actions.same_place(place, sky.place)
  if moved then
    -- a new window or a new size starts a fresh sky, embers never drift outside it
    if sky.target ~= win or not sky.place or sky.place.height ~= place.height then
      sky.embers = {}
    end
    place_float(place)
  end
  if not sky.win then
    return
  end
  sky.target, sky.place = win, place
  start_loop()
end

local EVENTS = {
  "WinScrolled",
  "WinResized",
  "VimResized",
  "CursorMoved",
  "BufEnter",
  "WinEnter",
  "TextChanged",
  "ModeChanged",
}

function M.setup()
  local group = vim.api.nvim_create_augroup("eldentree_drift", { clear = true })
  vim.api.nvim_create_autocmd(EVENTS, {
    group = group,
    -- a window mid change (textlock, a closing float) can refuse the sky, the next event tries again
    callback = function()
      pcall(M.update)
    end,
  })
  -- the layout settles after a window closes, so the sky looks again once it has
  vim.api.nvim_create_autocmd("WinClosed", {
    group = group,
    callback = function()
      vim.schedule(function()
        pcall(M.update)
      end)
    end,
  })
  -- a new region brings its own weather, and the motion switch stills the sky
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = { "EldentreeMotion", "EldentreeRegionSettled", "EldentreeFranchise" },
    callback = function()
      M.hide()
      M.update()
    end,
  })
end

return M
