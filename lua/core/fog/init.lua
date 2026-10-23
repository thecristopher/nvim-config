-- A fog wall rolls across the editor while you travel to another Site of Grace and thins away
-- once you arrive. It sits on a blended float, so the new project shows through the mist.
local actions = require("core.fog.actions")
local motion  = require("core.motion")

local M = {}

local current

local function define_highlights()
  local p = require("core.themes").palette()
  vim.api.nvim_set_hl(0, "EldenFog", { fg = p.overlay2, bg = p.surface0 })
end

local function close(state)
  if not state then return end
  if state.tween then state.tween:stop() end
  pcall(vim.api.nvim_win_close, state.win, true)
  pcall(vim.api.nvim_buf_delete, state.buf, { force = true })
end

local function open_float()
  local width, height = vim.o.columns, vim.o.lines - 1
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, actions.texture(width, height, math.random))

  local win = vim.api.nvim_open_win(buf, false, {
    relative  = "editor",
    row       = 0,
    col       = 0,
    width     = width,
    height    = height,
    style     = "minimal",
    border    = "none",
    focusable = false,
    -- above pickers and the tree, below banners so a new grace still reads through the fog
    zindex    = 200,
    noautocmd = true,
  })
  vim.wo[win].winhighlight = "Normal:EldenFog"
  vim.wo[win].winblend = 100
  return { buf = buf, win = win }
end

--- Rolls a fog wall over the editor and lets it fade, unless animations are stilled.
function M.roll()
  if not motion.enabled() or vim.g.eldentree_fog == false then return end
  close(current)
  local state = open_float()
  current = state
  state.tween = motion.tween({
    duration = actions.DURATION,
    easing   = "linear",
    frame_ms = 33,
    on_frame = function(_, raw)
      if vim.api.nvim_win_is_valid(state.win) then vim.wo[state.win].winblend = actions.blend_at(raw) end
    end,
    on_done  = function()
      close(state)
      if current == state then current = nil end
    end,
  })
end

function M.setup()
  define_highlights()
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("eldentree_fog", { clear = true }),
    callback = define_highlights,
  })
  vim.api.nvim_create_user_command("Fog", M.roll, { desc = "Walk through a fog wall" })
end

return M
