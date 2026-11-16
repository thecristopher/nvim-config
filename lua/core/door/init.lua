-- The screen goes dark, a door as tall as the screen slides open in the middle of it, and the dark
-- lifts off the project you arrive at. A blended float over the editor, like the fog wall it replaces.
local actions = require("core.door.actions")
local banner = require("core.banner.actions")
local motion = require("core.motion")
local color = require("core.motion.actions")

local M = {}

local ns = vim.api.nvim_create_namespace("eldentree_door")
local current

local function paint_groups(raw)
  local p = require("core.themes").palette()
  local dark = p.crust
  local blend = banner.blend_for(actions.darkness(raw))
  local wood = require("core.themes.actions").blend(p.peach, p.overlay0, 0.35)
  local fg = color.mix(color.to_int(dark), color.to_int(wood), actions.door_alpha(raw))
  vim.api.nvim_set_hl(0, "EldenDoorDark", { bg = dark, blend = blend })
  vim.api.nvim_set_hl(0, "EldenDoorPanel", { fg = fg, bg = dark, blend = blend })
  local note = color.mix(color.to_int(dark), color.to_int(p.overlay1), actions.door_alpha(raw))
  vim.api.nvim_set_hl(0, "EldenDoorLoading", { fg = note, bg = dark, blend = blend, italic = true })
end

local function close(state)
  if not state then
    return
  end
  if state.tween then
    state.tween:stop()
  end
  pcall(vim.api.nvim_win_close, state.win, true)
  pcall(vim.api.nvim_buf_delete, state.buf, { force = true })
end

local function open_float()
  local width, height = vim.o.columns, vim.o.lines - 1
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  local blank = (" "):rep(width)
  local lines = {}
  for row = 1, height do
    lines[row] = blank
  end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  local win = vim.api.nvim_open_win(buf, false, {
    relative = "editor",
    row = 0,
    col = 0,
    width = width,
    height = height,
    style = "minimal",
    border = "none",
    focusable = false,
    zindex = 200,
    noautocmd = true,
  })
  vim.wo[win].winblend = 1
  vim.wo[win].winhighlight = "Normal:EldenDoorDark"
  return { buf = buf, win = win, width = width, height = height }
end

local function put(state, row, col, text, group)
  if row >= 0 and row < state.height then
    vim.api.nvim_buf_set_extmark(state.buf, ns, row, 0, {
      virt_text = { { text, group } },
      virt_text_win_col = col,
      priority = 100,
    })
  end
end

local function draw_door(state, raw)
  vim.api.nvim_buf_clear_namespace(state.buf, ns, 0, -1)
  local width, height = actions.size(state.width, state.height)
  local rows = actions.rows(actions.swing(raw), width, height)
  local top = math.max(0, math.floor((state.height - #rows) / 2) - 1)
  local col = banner.center_col(state.width, width)
  for index, text in ipairs(rows) do
    put(state, top + index - 1, col, text, "EldenDoorPanel")
  end
  -- small at the bottom, the way the mansion's doors said it
  local loading = banner.spaced(require("core.franchise").current().words.loading or "")
  put(state, state.height - 2, math.max(0, state.width - #loading - 4), loading, "EldenDoorLoading")
end

--- Darkens the editor, swings a door open and lets the light back in, unless animations are stilled.
function M.open()
  if not motion.enabled() or vim.g.eldentree_fog == false then
    return
  end
  close(current)
  require("core.sound").play("door")
  local state = open_float()
  current = state
  paint_groups(0)
  state.tween = motion.tween({
    duration = actions.DURATION,
    easing = "linear",
    frame_ms = 40,
    on_frame = function(_, raw)
      if not vim.api.nvim_win_is_valid(state.win) then
        return
      end
      paint_groups(raw)
      draw_door(state, raw)
    end,
    on_done = function()
      close(state)
      if current == state then
        current = nil
      end
    end,
  })
end

return M
