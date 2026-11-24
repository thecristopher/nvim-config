-- The sign every travel shows (fog, door and curtain alike): the name of the place you arrive at,
-- between two gold rules on a dark plate, solid where the letters are so it reads over anything.
-- Also keeps the travel's promises: the arrival runs once the screen is covered, the rest once it clears.
local actions = require("core.signpost.actions")
local color = require("core.motion.actions")

local M = {}

M.actions = actions

local function blend_for(alpha)
  return require("core.banner.actions").blend_for(alpha)
end

--- Paints the sign's highlight groups for how visible it is right now.
---@param alpha number from 0 (gone) to 1 (fully shown)
function M.paint(alpha)
  local p = require("core.themes").palette()
  local plate = color.to_int(p.crust)
  for level = 0, actions.LEVELS do
    vim.api.nvim_set_hl(0, "EldenSignPlate" .. level, {
      bg = p.crust,
      blend = blend_for(alpha * actions.PLATE * level / actions.LEVELS),
    })
  end
  -- letters fade by color, not by blend, so they never ghost the travel behind them
  local solid = blend_for(math.min(1, alpha * 2))
  vim.api.nvim_set_hl(0, "EldenSignName", {
    fg = color.mix(plate, color.to_int(p.text), alpha),
    bg = p.crust,
    blend = solid,
    bold = true,
  })
  vim.api.nvim_set_hl(0, "EldenSignRule", {
    fg = color.mix(plate, color.to_int(p.yellow), alpha),
    bg = p.crust,
    blend = solid,
  })
end

local function put(buf, ns, row, col, chunks, priority)
  vim.api.nvim_buf_set_extmark(buf, ns, row, 0, {
    virt_text = chunks,
    virt_text_win_col = col,
    priority = priority,
  })
end

local function plate_chunks(width)
  local chunks = {}
  for _, run in ipairs(actions.plate_runs(width)) do
    table.insert(chunks, { (" "):rep(run[1]), "EldenSignPlate" .. run[2] })
  end
  return chunks
end

--- Draws the sign on a travel's full screen float. Call it after the travel drew its own frame.
---@param state { buf: integer, width: integer, height: integer, name: string|nil }
---@param ns integer the travel's namespace, cleared by the travel on every frame
---@param alpha number how visible the sign is
function M.draw(state, ns, alpha)
  if not state.name or state.name == "" or alpha <= 0 then
    return
  end
  local text = actions.text(state.name, state.width)
  local spot = actions.layout(state.width, state.height, vim.fn.strdisplaywidth(text))
  local plate = plate_chunks(spot.plate_width)
  for row = spot.top, spot.bottom do
    put(state.buf, ns, row, spot.plate_col, plate, 200)
  end
  local rule_above = actions.rule(spot.rule_width, true)
  put(state.buf, ns, spot.row - 1, spot.rule_col, { { rule_above, "EldenSignRule" } }, 210)
  put(state.buf, ns, spot.row, spot.col, { { text, "EldenSignName" } }, 210)
  local rule_below = actions.rule(spot.rule_width, false)
  put(state.buf, ns, spot.row + 1, spot.rule_col, { { rule_below, "EldenSignRule" } }, 210)
end

--- Runs the travel's arrival once, the moment the screen is covered (or right away without motion).
---@param state { on_covered: fun()|nil, covered: boolean|nil }
function M.arrive(state)
  if state.covered then
    return
  end
  state.covered = true
  if state.on_covered then
    state.on_covered()
  end
end

--- Arrives if it has not yet and then runs what waits for the screen to clear.
---@param state { on_covered: fun()|nil, on_done: fun()|nil, covered: boolean|nil }
function M.finish(state)
  M.arrive(state)
  if state.on_done then
    state.on_done()
  end
end

return M
