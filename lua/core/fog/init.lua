-- A fog wall rolls across the editor while you travel to another Site of Grace and thins away
-- once you arrive. Every cell is a space on a blended float, so the new project shows through.
local actions = require("core.fog.actions")
local motion = require("core.motion")
local signpost = require("core.signpost")

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
  -- a travel cut short by the next one still arrives, so no project is left half loaded
  signpost.arrive(state)
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

---@class TravelOpts
---@field on_covered? fun() runs once the screen is covered, the moment to load the new place
---@field on_done? fun() runs once the screen is clear again

--- Rolls a fog wall over the editor with the name of where you go, and lets it fade, unless
--- animations are stilled (then both callbacks run at once). Worlds that travel another way hand
--- off to the module named after it, like core.door.
---@param name string|nil where you are going, written on the sign
---@param opts? TravelOpts
function M.roll(name, opts)
  opts = opts or {}
  local travel = require("core.franchise").mechanic("travel")
  if travel ~= "fog" then
    return require("core." .. travel).open(name, opts)
  end
  local state = { name = name, on_covered = opts.on_covered, on_done = opts.on_done }
  if not motion.enabled() or vim.g.eldentree_fog == false then
    return signpost.finish(state)
  end
  close(current)
  require("core.sound").play("fog")
  state = vim.tbl_extend("force", open_float(), state)
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
      local sign = signpost.actions.alpha(raw, actions.SIGN.from, actions.SIGN.to)
      signpost.paint(sign)
      signpost.draw(state, ns, sign)
      if raw >= actions.COVERED and not state.covered then
        vim.schedule(function()
          signpost.arrive(state)
        end)
      end
    end,
    on_done = function()
      close(state)
      if current == state then
        current = nil
      end
      signpost.finish(state)
    end,
  })
end

function M.setup()
  vim.api.nvim_create_user_command("Fog", function()
    M.roll()
  end, { desc = "Walk through a fog wall" })
end

return M
