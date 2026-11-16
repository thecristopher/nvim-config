-- The Resident Evil hub: the STATUS panel with the survivor's portrait standing tall over their name,
-- area and condition, the attaché case under plate tabs (one lattice of cells where the important
-- items take two or four, empty cells waiting with a dot and counts in green ammo digits) with the
-- COMMAND menu, the DATA of the quest you left open, and the selected item's name across the bottom
-- like the old item banners, its description struck in by the typewriter beside the ink ribbons.
-- Everything sits centered on screen at any size. Pure: model in, rows out.
local hud = require("core.hud.actions")
local parts = require("core.hud.views.parts")

local M = {}

M.MARGIN = 2
M.GAP = 3
M.SLOT_WIDTH = 16
M.SLOT_HEIGHT = 4
M.MENU_WIDTH = 13
M.STATUS_MIN = 42
M.COLUMNS = { min = 2, max = 4 }
M.GRID_ROWS = { min = 1, max = 4 }
M.PORTRAIT = { min = 4, max = 32 }
-- the STATUS frame around the portrait: borders, gaps, the name, the area and the condition
M.STATUS_ROWS = 8
-- the carriage of the typewriter, sitting after the last letter it struck
M.CARET = "▌"
-- under the stage: a gap, the banner, two lines of description, the hints, a gap and the message
M.FOOTER_ROWS = 7
M.DATA_ROWS = 5
M.CHANGE_ROWS = 2

local FRAMES = {
  normal = {
    tl = "╔",
    tr = "╗",
    bl = "╚",
    br = "╝",
    h = "═",
    v = "║",
    hl = "EldenHudFrame",
  },
  selected = {
    tl = "╔",
    tr = "╗",
    bl = "╚",
    br = "╝",
    h = "═",
    v = "║",
    hl = "EldenHudFrameSel",
  },
}

-- sizes -----------------------------------------------------------------------------------

local function items_width(columns)
  return columns * M.SLOT_WIDTH + 1 + M.MENU_WIDTH
end

-- rows the right column takes besides the grid: the plates and their gap, the case's bottom wall
-- and the DATA box. A gap between the case and DATA comes only from rows left over
local function fixed_rows(change_rows)
  return 2 + 1 + 2 + M.DATA_ROWS + change_rows
end

-- every way the hub can stand: STATUS with the portrait beside items of two columns or more,
-- beside a single column, or shrunk to the survivor's name above the items with the portrait over
-- it. The plan keeps the one with the biggest portrait
local SHAPES = {
  { beside = true, columns = M.COLUMNS.min },
  { beside = true, columns = 1 },
  { beside = false },
}

-- the portrait inside the STATUS frame beside items of that many columns
local function portrait_beside(inner, room, columns)
  return hud.portrait_fit(
    inner - M.GAP - items_width(columns) - 6,
    math.min(room - M.STATUS_ROWS, M.PORTRAIT.max),
    M.PORTRAIT.min
  )
end

-- the portrait above the survivor's name on a narrow screen, taking the rows the smallest
-- grid leaves, plus a gap before the name
local function portrait_above(width, room, change_rows)
  local body_rows = fixed_rows(change_rows) + M.GRID_ROWS.min * M.SLOT_HEIGHT
  return hud.portrait_fit(width, math.min(room - body_rows - 1, M.PORTRAIT.max), M.PORTRAIT.min)
end

-- the whole plan for one shape, stacked anyway when STATUS does not fit beside the items
local function shape_plan(model, shape)
  local inner = model.width - 2 * M.MARGIN
  local fits_beside = shape.beside and inner >= M.STATUS_MIN + M.GAP + items_width(shape.columns)
  local stacked = not fits_beside
  local room = model.height - 2 - M.FOOTER_ROWS - (stacked and 2 or 0)
  local change_rows = room - fixed_rows(M.CHANGE_ROWS) >= M.SLOT_HEIGHT and M.CHANGE_ROWS or 0
  local portrait = not stacked and model.portrait and portrait_beside(inner, room, shape.columns)
    or nil
  local status_width = math.max(M.STATUS_MIN, portrait and portrait.width + 6 or 0)
  local beside = stacked and 0 or status_width + M.GAP
  local columns =
    hud.clamp(math.floor((inner - beside - 1 - M.MENU_WIDTH) / M.SLOT_WIDTH), 1, M.COLUMNS.max)
  if stacked and model.portrait then
    status_width = items_width(columns)
    portrait = portrait_above(status_width, room, change_rows)
    -- the changed files give their rows up before the portrait does
    if not portrait and change_rows > 0 then
      change_rows = 0
      portrait = portrait_above(status_width, room, change_rows)
    end
  elseif stacked then
    status_width = items_width(columns)
  end
  local above = (stacked and portrait) and portrait.height + 1 or 0
  local grid_rows = hud.clamp(
    math.floor((room - above - fixed_rows(change_rows)) / M.SLOT_HEIGHT),
    M.GRID_ROWS.min,
    M.GRID_ROWS.max
  )
  local stage_width = beside + items_width(columns)
  local spare = room - above - fixed_rows(change_rows) - grid_rows * M.SLOT_HEIGHT
  return {
    gap = spare >= 1,
    portrait = portrait,
    status_width = status_width,
    columns = columns,
    grid_rows = grid_rows,
    change_rows = change_rows,
    items_width = items_width(columns),
    stacked = stacked,
    stage_width = stage_width,
    indent = math.max(0, math.floor((model.width - stage_width) / 2)),
  }
end

--- Decides how big everything is for a window: the portrait, the STATUS panel and the grid.
--- The portrait comes first: every shape is tried and the one where it stands tallest wins.
---@param model table needs width, height and portrait
---@return table plan { portrait?, status_width, columns, grid_rows, change_rows, items_width, stacked, stage_width, indent }
function M.plan(model)
  if not model.portrait then
    return shape_plan(model, SHAPES[1])
  end
  return hud.biggest_portrait(vim.tbl_map(function(shape)
    return shape_plan(model, shape)
  end, SHAPES))
end

-- frames ----------------------------------------------------------------------------------

local function boxed(title, body, width, lit)
  local inner = width - 2
  local label = title ~= "" and ("═ " .. title .. " ") or ""
  local rows = {
    {
      {
        "╔" .. label .. ("═"):rep(inner - vim.api.nvim_strwidth(label)) .. "╗",
        lit and "EldenHudFrameSel" or "EldenHudFrame",
      },
    },
  }
  for _, chunks in ipairs(body) do
    local row = { { "║", "EldenHudFrame" } }
    vim.list_extend(row, hud.pad_chunks(hud.clip(chunks, inner), inner))
    table.insert(row, { "║", "EldenHudFrame" })
    table.insert(rows, row)
  end
  table.insert(rows, { { "╚" .. ("═"):rep(inner) .. "╝", "EldenHudFrame" } })
  return rows
end

-- a narrow screen keeps the survivor as one line over the items
local function status_line(model, plan)
  local status = model.status or {}
  local name = {
    { status.character and status.character:upper() or "", "EldenHudBanner" },
    { "  ·  " .. (status.area or ""), "EldenHudSection" },
  }
  local rows = {}
  if plan.portrait then
    local left = math.floor((plan.status_width - plan.portrait.width) / 2)
    table.insert(rows, { { (" "):rep(left) }, { "", spot = "portrait" } })
    for _ = 2, plan.portrait.height do
      table.insert(rows, {})
    end
    table.insert(rows, {})
  end
  if model.condition then
    table.insert(name, { "  ·  " .. model.condition.word, model.condition.hl })
  end
  -- the name first, then the area and the condition while each fits whole
  local line = { name[1] }
  for index = 2, #name do
    if hud.width(line) + hud.width({ name[index] }) <= plan.status_width then
      table.insert(line, name[index])
    end
  end
  table.insert(rows, hud.center(line, plan.status_width))
  table.insert(rows, {})
  return rows
end

-- STATUS: the portrait float is drawn by the HUD over the blank cells after the spot
local function status_panel(model, plan)
  if plan.stacked then
    return status_line(model, plan)
  end
  local inner = plan.status_width - 2
  local status = model.status or {}
  local body = { {} }
  if plan.portrait then
    local left = math.floor((inner - plan.portrait.width) / 2)
    table.insert(body, { { (" "):rep(left) }, { "", spot = "portrait" } })
    for _ = 2, plan.portrait.height do
      table.insert(body, {})
    end
    table.insert(body, {})
  end
  table.insert(
    body,
    hud.center(
      { { parts.champion_name(status.character or "", inner - 2), "EldenHudBanner" } },
      inner
    )
  )
  table.insert(body, parts.whole_line(status.area, "EldenHudSection", inner))
  -- the condition the old STATUS screens printed under the survivor, in its own color
  local condition = model.condition
  table.insert(body, condition and hud.center({ { condition.word, condition.hl } }, inner) or {})
  return boxed("STATUS", body, plan.status_width)
end

-- the items ---------------------------------------------------------------------------------

local function tab_plates(model)
  local row = {}
  for index, tab in ipairs(model.tabs) do
    table.insert(row, {
      " " .. tab.title .. " ",
      index == model.tab and "EldenHudTabSel" or "EldenHudTab",
      spot = index == 1 and "fallback" or nil,
    })
    table.insert(row, { " " })
  end
  return row
end

-- the attaché case ---------------------------------------------------------------------------
-- drawn on a canvas of cells: every wall and joint of the lattice first, then each item's text in
-- the room its cells leave, then the canvas turns back into rows of chunks

local function blank_canvas(height, width)
  local canvas = {}
  for y = 1, height do
    canvas[y] = {}
    for x = 1, width do
      canvas[y][x] = { " " }
    end
  end
  return canvas
end

-- writes text from a cell on, one character per cell, a wide one leaving the next cell empty
local function write(canvas, y, x, text, hl, bg, spot)
  for index = 0, vim.fn.strchars(text) - 1 do
    local char = vim.fn.strcharpart(text, index, 1)
    if canvas[y] and canvas[y][x] then
      canvas[y][x] = { char, hl, bg = bg, spot = index == 0 and spot or nil }
      local wide = vim.api.nvim_strwidth(char) > 1
      if wide and canvas[y][x + 1] then
        canvas[y][x + 1] = { "", hl, bg = bg }
      end
      x = x + (wide and 2 or 1)
    end
  end
end

-- who owns a cell of the case as the window shows it: an item's index, false for an empty cell
-- and "out" past the case or the rows in view
local function owner(case, first, last, row, col)
  if row < first or row > last or col < 1 or col > case.columns then
    return "out"
  end
  return (case.cells[row] or {})[col] or false
end

local function walled(a, b)
  if a == "out" and b == "out" then
    return false
  end
  return a ~= b or a == false
end

-- a wall glows with the selected item, stays plain beside any item and fades between empty cells
local function wall_hl(a, b, selected)
  if a == selected or b == selected then
    return "EldenHudFrameSel", 3
  end
  if type(a) == "number" or type(b) == "number" then
    return "EldenHudFrame", 2
  end
  return "EldenHudCase", 1
end

local function strongest(walls)
  local best, rank = "EldenHudCase", 0
  for _, wall in ipairs(walls) do
    if wall.on and wall.rank > rank then
      best, rank = wall.hl, wall.rank
    end
  end
  return best
end

local function segment(a, b, selected)
  local on = walled(a, b)
  local hl, rank = wall_hl(a, b, selected)
  return { on = on, hl = hl, rank = rank }
end

-- the wall leaving a joint to the right and the one leaving it downward, as far as the next joint
local function wall_runs(canvas, y, x, right, down)
  for step = 1, M.SLOT_WIDTH - 1 do
    if right.on and canvas[y][x + step] then
      canvas[y][x + step] = { "═", right.hl }
    end
  end
  for step = 1, M.SLOT_HEIGHT - 1 do
    if down.on and canvas[y + step] then
      canvas[y + step][x] = { "║", down.hl }
    end
  end
end

-- the joints and walls around every cell of the rows in view
local function draw_walls(canvas, case, view)
  local function at(row, col)
    return owner(case, view.first, view.last, view.first + row - 1, col)
  end
  for r = 1, view.rows + 1 do
    for c = 1, case.columns + 1 do
      local nw, ne, sw, se = at(r - 1, c - 1), at(r - 1, c), at(r, c - 1), at(r, c)
      local up, down = segment(nw, ne, view.selected), segment(sw, se, view.selected)
      local left, right = segment(nw, sw, view.selected), segment(ne, se, view.selected)
      local y, x = (r - 1) * M.SLOT_HEIGHT + 1, (c - 1) * M.SLOT_WIDTH + 1
      canvas[y][x] = {
        hud.joint(up.on, down.on, left.on, right.on),
        strongest({ up, down, left, right }),
      }
      wall_runs(canvas, y, x, right, down)
    end
  end
end

-- an item's text in the room its cells leave inside the walls
local function draw_item(canvas, item, spot, view)
  local top = (spot.row - view.first) * M.SLOT_HEIGHT + 2
  local left = (spot.col - 1) * M.SLOT_WIDTH + 2
  local width = spot.w * M.SLOT_WIDTH - 1
  local height = spot.h * M.SLOT_HEIGHT - 1
  local selected = item == view.selected_item
  local bg = selected and "EldenHudSlotSel" or nil
  for y = top, top + height - 1 do
    if y > top - 1 and canvas[y] and y > 1 and y < #canvas then
      for x = left, left + width - 1 do
        canvas[y][x] = { " ", bg = bg }
      end
    end
  end
  local icon = hud.pad(vim.trim(item.icon or "·"), 2)
  write(canvas, top, left + 1, icon, item.icon_hl or "EldenHudIcon", bg, selected and "cursor")
  local name = hud.fit_name(item.slot or item.name, width - 5)
  write(canvas, top, left + 4, name, selected and "EldenHudName" or "EldenHudDesc", bg)
  if spot.w > 1 and item.category and vim.api.nvim_strwidth(item.category) <= width - 5 then
    write(canvas, top + 1, left + 4, item.category, "EldenHudSection", bg)
  end
  local bottom = top + height - 1
  local key = item.key and ("[" .. item.key .. "]") or ""
  write(canvas, bottom, left + 1, key, "EldenHudKey", bg)
  local count = item.count and tostring(item.count) or ""
  write(canvas, bottom, left + width - 1 - vim.fn.strchars(count), count, "EldenHudAmmo", bg)
end

-- an empty cell waits with a dot in its middle
local function draw_empty(canvas, view, row, col)
  local y = (row - view.first) * M.SLOT_HEIGHT + 3
  local x = (col - 1) * M.SLOT_WIDTH + math.floor(M.SLOT_WIDTH / 2) + 1
  if canvas[y] and canvas[y][x] then
    canvas[y][x] = { "·", "EldenHudCase" }
  end
end

-- one row of the canvas as chunks, cells sharing a look joined into one
local function canvas_row(cells)
  local chunks = {}
  for _, cell in ipairs(cells) do
    local last = chunks[#chunks]
    if last and not cell.spot and last[2] == cell[2] and last.bg == cell.bg then
      last[1] = last[1] .. cell[1]
    else
      table.insert(chunks, { cell[1], cell[2], bg = cell.bg, spot = cell.spot })
    end
  end
  return chunks
end

--- Draws the attaché case for the rows in view.
---@param items table[]
---@param case table from hud.pack
---@param cursor integer the selected item
---@param offset integer first cell row in view, from 0
---@param visible integer cell rows in view
---@return table[] rows of chunks
local function case_rows(items, case, cursor, offset, visible)
  local view = {
    first = offset + 1,
    last = offset + visible,
    rows = visible,
    selected = items[cursor] and cursor or nil,
    selected_item = items[cursor],
  }
  local canvas = blank_canvas(visible * M.SLOT_HEIGHT + 1, case.columns * M.SLOT_WIDTH + 1)
  draw_walls(canvas, case, view)
  for row = view.first, view.last do
    for col = 1, case.columns do
      if not (case.cells[row] or {})[col] then
        draw_empty(canvas, view, row, col)
      end
    end
  end
  for index, item in ipairs(items) do
    local spot = case.places[index]
    if spot.row + spot.h - 1 >= view.first and spot.row <= view.last then
      draw_item(canvas, item, spot, view)
    end
  end
  return vim.tbl_map(canvas_row, canvas)
end

local function command_menu(menu)
  if not menu then
    return {}
  end
  local rows = { { { "┌ COMMAND ─┐", "EldenHudFrame" } } }
  for index, entry in ipairs(menu.entries) do
    local active = index == menu.index
    local hl = not entry.enabled and "EldenHudDim" or active and "EldenHudTabSel" or "EldenHudName"
    table.insert(rows, {
      { "│", "EldenHudFrame" },
      { hud.pad((active and "▶" or " ") .. entry.label, 9), hl },
      { "│", "EldenHudFrame" },
    })
  end
  table.insert(rows, { { "└──────────┘", "EldenHudFrame" } })
  return rows
end

local function data_box(model, plan)
  local status = model.status or {}
  local width = plan.items_width
  local value = width - 2 - 8
  local last_selected, change = parts.quest_selection(model)
  -- a value whole, its part before the first dot, or a name cut where it breaks
  local function field(label, text, hl)
    text = text or "·"
    local shown = hud.first_fit({ text, text:match("^(.-)%s+·") }, value)
      or hud.fit_name(text, value)
    return {
      { " " .. hud.pad(label, 7), "EldenHudDim" },
      { shown, hl or "EldenHudName" },
    }
  end
  local last = field("LAST", status.last_file)
  if last_selected then
    last = {
      { " " .. hud.pad("▶ LAST", 7), "EldenHudFrameSel" },
      {
        hud.fit_name(status.last_file, value),
        "EldenHudBanner",
        bg = "EldenHudSlotSel",
        spot = "cursor",
      },
    }
  end
  local body = {
    hud.indent({
      parts.quest_line(
        status,
        width - 4,
        "No quest here, BOX holds your " .. (model.sites or "projects")
      ),
    }, 1)[1],
    last,
    field("TYPE", status.filetype),
    field("PURSE", status.purse, "EldenHudCount"),
    field("RANK", status.last_run or "no run ranked yet"),
  }
  local changes = parts.changes(status.changes or {}, width - 4, plan.change_rows, change)
  for row = 1, plan.change_rows do
    table.insert(body, hud.indent({ changes[row] or {} }, 1)[1])
  end
  local focused = model.focus == "quest"
  return boxed(focused and "DATA ▼" or "DATA  j", body, width, focused)
end

-- stretch adds empty rows above the DATA box, so the column can end where STATUS ends
local function items_column(model, plan, stretch)
  local items = model.tabs[model.tab].items
  local cursor = model.cursor.items or 1
  local case = hud.pack(items, plan.columns)
  local offset = hud.case_scroll(case.places[cursor], plan.grid_rows, model.offset.items or 0)
  local slots = case_rows(items, case, cursor, offset, plan.grid_rows)
  local rows = { tab_plates(model), {} }
  local grid_area = hud.beside(slots, plan.columns * M.SLOT_WIDTH + 1, command_menu(model.menu), 0)
  -- the case keeps its height whatever the tab holds, so nothing below it moves
  while #grid_area < plan.grid_rows * M.SLOT_HEIGHT + 1 do
    table.insert(grid_area, {})
  end
  vim.list_extend(rows, grid_area)
  for _ = 1, (plan.gap and 1 or 0) + (stretch or 0) do
    table.insert(rows, {})
  end
  vim.list_extend(rows, data_box(model, plan))
  local spot = case.places[cursor]
  return rows,
    {
      columns = plan.columns,
      count = #items,
      offset = offset,
      cursor_row = spot and spot.row - 1 or 0,
      case = case,
    }
end

-- the DATA entries walk one after another, the last file first, then every change with room
local function quest_grid(model, change_rows)
  local cursor = model.cursor.quest or 1
  return {
    columns = 1,
    count = parts.quest_count(model.status or {}, change_rows),
    offset = 0,
    cursor_row = cursor - 1,
  }
end

-- the bottom ------------------------------------------------------------------------------

-- the ink ribbons sit at the right end of the banner's rule, like the count beside the typewriter
local function ribbon_tail(ribbons, room)
  if not ribbons then
    return { { ("═"):rep(room), "EldenHudFrame" } }
  end
  local note = (" %s ×%d "):format(ribbons.word, ribbons.count)
  local width = vim.api.nvim_strwidth(note)
  if room < width + 6 then
    return { { ("═"):rep(room), "EldenHudFrame" } }
  end
  return {
    { ("═"):rep(room - width - 2), "EldenHudFrame" },
    { note, "EldenHudAmmo" },
    { "══", "EldenHudFrame" },
  }
end

-- "Ink Ribbon" becomes "I N K   R I B B O N", letter by letter so accents stay whole
local function spaced(text)
  return table.concat(vim.fn.split(vim.fn.toupper(text), "\\zs"), " ")
end

local function banner(item, width, typed, ribbons)
  -- spaced when it fits, plain capitals when it does not, cut where it breaks as a last resort
  local upper = item and vim.fn.toupper(item.name) or ""
  local name = item
      and (hud.first_fit({ spaced(item.name), upper }, width - 8) or hud.fit_name(upper, width - 8))
    or ""
  local side = math.max(2, math.floor((width - vim.api.nvim_strwidth(name) - 4) / 2))
  local head = {
    { ("═"):rep(side) .. "╡ ", "EldenHudFrame" },
    { name, "EldenHudBanner" },
    { " ╞", "EldenHudFrame" },
  }
  vim.list_extend(head, ribbon_tail(ribbons, width - side - vim.api.nvim_strwidth(name) - 4))
  local rows = { head }
  local lines = hud.typed_with_caret(
    item and hud.wrap_rows(item.desc or "", width - 2, 2) or {},
    typed,
    M.CARET
  )
  for index = 1, 2 do
    table.insert(rows, hud.center({ { lines[index] or "", "EldenHudDesc" } }, width))
  end
  return rows
end

-- most important first, a narrow screen drops them from the end, Enter opens the COMMAND menu
local HINTS = {
  { "⏎", "command" },
  { "K", "check" },
  { "⇥", "tabs" },
  { "hjkl", "move" },
  { "j", "quest" },
  { "s", "session" },
  { "q", "quit" },
}

--- Lays out the whole Resident Evil hub for a model.
---@param model table HUD state: tabs, tab, cursor, offset, menu, status, message, width, height
---@return table view { lines, marks, cursor, grids, anchors, plan }
function M.render(model)
  local plan = M.plan(model)
  local status = status_panel(model, plan)
  local items, items_grid = items_column(model, plan)
  local rows
  if plan.stacked then
    rows = vim.list_extend(status, items)
  else
    -- both columns share their top and bottom edges: the plates start where STATUS starts and
    -- DATA ends where it ends, the room left over goes between the grid and DATA
    if #items < #status then
      items, items_grid = items_column(model, plan, #status - #items)
    end
    local height = math.max(#status, #items)
    rows = hud.beside(hud.middle(status, height), plan.status_width, items, M.GAP)
  end
  table.insert(rows, {})
  vim.list_extend(rows, banner(parts.selected(model), plan.stage_width, model.typed, model.ribbons))
  table.insert(
    rows,
    hud.center(
      hud.hint_chunks(parts.hints(model, HINTS), plan.stage_width, "EldenHudKey", "EldenHudHint"),
      plan.stage_width
    )
  )
  -- the song playing sits in the gap over the message
  table.insert(rows, parts.player(model.music, plan.stage_width) or {})
  table.insert(rows, parts.whole_line(model.message, "SnacksDashboardDesc", plan.stage_width))
  local lines, marks, spots = hud.compose(hud.indent(rows, plan.indent))

  local cursor = spots.cursor or spots.fallback
  local anchors = {}
  if plan.portrait and spots.portrait then
    anchors.portrait = vim.tbl_extend("force", spots.portrait, plan.portrait)
  end
  return {
    lines = lines,
    marks = marks,
    anchors = anchors,
    plan = plan,
    grids = { items = items_grid, quest = quest_grid(model, plan.change_rows) },
    cursor = { row = cursor.row + 1, col = cursor.col },
  }
end

return M
