-- A fog wall rolls across the editor while you travel to another Site of Grace and thins away
-- once you arrive. Every cell is a space on a blended float, so the new project shows through.
local actions = require("core.fog.actions")
local motion = require("core.motion")

local M = {}

local ns = vim.api.nvim_create_namespace("eldentree_fog")
local current

-- the milky gold of the game's fog walls, taken from the region so it never clashes
local function fog_color()
  local p = require("core.themes").palette()
  return require("core.themes.actions").blend(p.text, p.overlay1, 0.55)
end

local function paint_groups(density)
  local color = fog_color()
  for level = 0, actions.LEVELS do
    vim.api.nvim_set_hl(
      0,
      "EldenFog" .. level,
      { bg = color, blend = actions.blend_for(level, density) }
    )
  end
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
    -- above pickers and the tree, below banners so a new grace still reads through the fog
    zindex = 200,
    noautocmd = true,
  })
  -- any winblend switches on per cell blending, the groups then choose their own amount
  vim.wo[win].winblend = 1
  vim.wo[win].winhighlight = "Normal:EldenFog0"
  return { buf = buf, win = win, width = width, height = height, seed = math.random() * 100 }
end

local function draw_clouds(state, raw)
  vim.api.nvim_buf_clear_namespace(state.buf, ns, 0, -1)
  local drift = raw * actions.DRIFT
  for row = 0, state.height - 1 do
    local levels = actions.row_levels(state.width, row, state.height, state.seed, drift)
    for _, run in ipairs(actions.runs(levels)) do
      if run[3] > 0 then
        vim.api.nvim_buf_set_extmark(
          state.buf,
          ns,
          row,
          run[1],
          { end_col = run[2], hl_group = "EldenFog" .. run[3] }
        )
      end
    end
  end
end

--- Rolls a fog wall over the editor and lets it fade, unless animations are stilled.
--- Worlds that travel through doors open one instead.
function M.roll()
  if require("core.franchise").mechanic("travel") == "door" then
    return require("core.door").open()
  end
  if not motion.enabled() or vim.g.eldentree_fog == false then
    return
  end
  close(current)
  require("core.sound").play("fog")
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
      paint_groups(actions.density_at(raw))
      draw_clouds(state, raw)
    end,
    on_done = function()
      close(state)
      if current == state then
        current = nil
      end
    end,
  })
end

function M.setup()
  vim.api.nvim_create_user_command("Fog", M.roll, { desc = "Walk through a fog wall" })
end

return M
