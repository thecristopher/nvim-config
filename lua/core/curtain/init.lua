-- The stage curtain: velvet drapes close over the editor from both sides, the next stage is
-- announced on them, and they part on the project you arrive at. A float over the editor like
-- the fog wall and the door, where only the drapes are solid and the gap between them is clear.
local actions = require("core.curtain.actions")
local banner = require("core.banner.actions")
local motion = require("core.motion")
local signpost = require("core.signpost")

local M = {}

local ns = vim.api.nvim_create_namespace("eldentree_curtain")
local current

-- the velvet takes the stage accent, so every costume brings its own curtain
local function paint_groups()
  local p = require("core.themes").palette()
  local blend = require("core.themes.actions").blend
  local deep = blend(p.yellow, p.crust, 0.28)
  local lit = blend(p.yellow, p.crust, 0.72)
  vim.api.nvim_set_hl(0, "EldenCurtainGap", { bg = p.crust, blend = 100 })
  for shade = 1, actions.SHADES do
    local fg = blend(lit, deep, (shade - 1) / (actions.SHADES - 1))
    vim.api.nvim_set_hl(0, "EldenCurtainFold" .. shade, { fg = fg, bg = deep })
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
    zindex = 200,
    noautocmd = true,
  })
  -- a blended window lets each group choose: the gap stays clear, the velvet stays solid
  vim.wo[win].winblend = 1
  vim.wo[win].winhighlight = "Normal:EldenCurtainGap"
  return { buf = buf, win = win, width = width, height = height }
end

local function velvet(width, side)
  local chunks = {}
  for _, run in ipairs(actions.runs(width, side)) do
    table.insert(chunks, { ("█"):rep(run[1]), "EldenCurtainFold" .. run[2] })
  end
  return chunks
end

local function draw(state, raw)
  vim.api.nvim_buf_clear_namespace(state.buf, ns, 0, -1)
  local drape = actions.drape_width(state.width, actions.cover(raw))
  if drape == 0 then
    return
  end
  local left, right = velvet(drape, "left"), velvet(drape, "right")
  for row = 0, state.height - 1 do
    vim.api.nvim_buf_set_extmark(state.buf, ns, row, 0, {
      virt_text = left,
      virt_text_win_col = 0,
      priority = 100,
    })
    vim.api.nvim_buf_set_extmark(state.buf, ns, row, 0, {
      virt_text = right,
      virt_text_win_col = state.width - drape,
      priority = 100,
    })
  end
end

--- Closes the curtain over the editor, announces the next stage on it and opens again, unless
--- animations are stilled (then both callbacks run at once).
---@param name string|nil the stage being announced, like the project or branch you travel to
---@param opts? TravelOpts
function M.open(name, opts)
  opts = opts or {}
  local state = { name = name, on_covered = opts.on_covered, on_done = opts.on_done }
  if not motion.enabled() or vim.g.eldentree_fog == false then
    return signpost.finish(state)
  end
  close(current)
  require("core.sound").play("curtain")
  state = vim.tbl_extend("force", open_float(), state)
  current = state
  paint_groups()
  state.tween = motion.tween({
    duration = actions.DURATION,
    easing = "linear",
    frame_ms = 40,
    on_frame = function(_, raw)
      if not vim.api.nvim_win_is_valid(state.win) then
        return
      end
      draw(state, raw)
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

return M
