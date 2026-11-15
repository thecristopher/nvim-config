-- Elizabeth's dressing room. A marquee sign over a clothes rail the tabs hang from as tags, the
-- rack of the tab's pieces in a cabinet with a close up of the selected piece under it, the
-- stages on the other side with the call sheet of the quest you left open, and her whole figure
-- in a vanity mirror ringed with bulbs over a dressing table with her name. Everything sits
-- centered on screen at any size. Pure: model in, rows out.
local hud = require("core.hud.actions")
local parts = require("core.hud.views.parts")

local M = {}

M.MARGIN = 2
M.GAP = 3
M.TAB_WIDTH = 6
-- compact is how narrow a column may get when the mirror needs the room
M.RACK_WIDTH = { compact = 22, min = 28, max = 44 }
M.STAGE_WIDTH = { compact = 26, min = 32, max = 50 }
-- comfort is how tall the mirror must stand between the columns before another shape is tried
M.PORTRAIT = { min = 4, comfort = 16, max = 34 }
-- the bulbs ring the portrait: a bulb and a space on each side, a row of bulbs above and below
M.MIRROR_COLS = 4
M.MIRROR_ROWS = 2
-- under the mirror: the dressing table, the character's name and the stage
M.NAME_ROWS = 3
M.QUEST_CHANGE_ROWS = 3
-- above the columns the sign, a gap, the rail and its tags and a gap; under them a gap and the hints
M.TOP_ROWS = 7
M.BOTTOM_ROWS = 2
-- the close up card holds the piece's name and two lines about it
M.CLOSE_UP_ROWS = 3
-- the columns grow no taller than this when nothing beside them asks for more
M.SIDE_MAX = 22
-- the marker, key, icon and gap before a piece's name
M.ROW_PREFIX = 7
-- the narrowest a column of changed files reads well at
M.CHANGE_COLUMN = 30
-- the view shows whole figures, so the HUD hands it a region's figure when there is one
M.SHOWS_FIGURES = true

M.BULB = "◉"

-- sizes -----------------------------------------------------------------------------------

local function fixed_rows()
  return M.TOP_ROWS + M.BOTTOM_ROWS
end

-- a frame takes a row above and below what it holds
local function rack_rows_for(side)
  return side - 2 - (M.CLOSE_UP_ROWS + 2)
end

-- the call sheet's title is its top edge, then the project, the branch, the last file, the
-- changes and the bottom edge
local function stage_rows_for(side, quest_rows)
  return side - 2 - (4 + quest_rows + 1)
end

-- the shortest columns that still show three pieces and two stages
local function side_min(quest_rows)
  return math.max(3 + 2 + M.CLOSE_UP_ROWS + 2, 2 + 2 + 4 + quest_rows + 1)
end

-- the bulbs need one on both corners, so the mirror is always an odd number of cells wide
local function mirror_width(portrait)
  local width = portrait.width + M.MIRROR_COLS
  return width % 2 == 0 and width + 1 or width
end

local function mirror_height(portrait)
  return portrait.height + M.MIRROR_ROWS + M.NAME_ROWS
end

local function body_width(rack, stage)
  return rack + M.GAP + stage
end

-- the rack and the stages share the width the mirror leaves, the stages taking a little more
local function column_widths(space)
  local rack = hud.clamp(math.floor((space - M.GAP) * 0.45), M.RACK_WIDTH.compact, M.RACK_WIDTH.max)
  local stage = hud.clamp(space - M.GAP - rack, M.STAGE_WIDTH.compact, M.STAGE_WIDTH.max)
  return rack, stage
end

-- the cells and rows a shape leaves the portrait: between the columns, aside the whole body as
-- tall as the screen, or above the whole body
local function mirror_room(shape, inner, room, quest_rows)
  local ring = M.MIRROR_ROWS + M.NAME_ROWS
  -- one more cell for the padding an even width gets
  local cols = M.MIRROR_COLS + 1
  if shape == "between" then
    local columns = body_width(M.RACK_WIDTH.min, M.STAGE_WIDTH.min)
    return inner - columns - 2 * M.GAP - cols, room - fixed_rows() - ring
  end
  if shape == "aside" then
    local columns = body_width(M.RACK_WIDTH.compact, M.STAGE_WIDTH.compact)
    return inner - columns - M.GAP - cols, room - ring
  end
  return inner - cols, room - fixed_rows() - side_min(quest_rows) - 1 - ring
end

local function fit_portrait(model, shape, inner, room, quest_rows)
  if not model.portrait then
    return nil
  end
  local width, height = mirror_room(shape, inner, room, quest_rows)
  local ratio = model.figure and hud.FIGURE_RATIO or nil
  return hud.portrait_fit(width, math.min(height, M.PORTRAIT.max), M.PORTRAIT.min, ratio)
end

-- how tall both columns stand: as tall as the mirror between them up to SIDE_MAX, so a tall
-- mirror is flanked by two cabinets instead of two empty towers, or what the room leaves
local function side_for(shape, portrait, room, quest_rows)
  local low = side_min(quest_rows)
  if shape == "between" then
    return hud.clamp(mirror_height(portrait), low, math.max(low, M.SIDE_MAX))
  end
  local above = shape == "above" and mirror_height(portrait) + 1 or 0
  return hud.clamp(room - fixed_rows() - above, low, M.SIDE_MAX)
end

-- the width the columns leave beside the mirror, by where the mirror stands
local function columns_space(shape, inner, mirror)
  if shape == "between" then
    return inner - mirror - 2 * M.GAP + M.GAP
  end
  if shape == "aside" then
    return inner - mirror - M.GAP
  end
  return inner
end

local function shape_plan(model, shape)
  local inner = model.width - 2 * M.MARGIN
  local room = model.height - 2 - parts.FOOTER_ROWS
  -- the call sheet's changes are the first rows to go on a short screen
  local quest_rows = room - fixed_rows() >= side_min(M.QUEST_CHANGE_ROWS) + 2
      and M.QUEST_CHANGE_ROWS
    or 0
  local portrait = fit_portrait(model, shape, inner, room, quest_rows)
  local placed = portrait and shape or "none"
  local mirror = portrait and mirror_width(portrait) or 0
  local rack, stage = column_widths(columns_space(placed, inner, mirror))
  local width = body_width(rack, stage) + (placed == "between" and mirror + M.GAP or 0)
  local stage_width = width + (placed == "aside" and mirror + M.GAP or 0)
  local side = side_for(placed, portrait, room, quest_rows)
  return {
    shape = placed,
    portrait = portrait,
    stacked = placed == "above",
    mirror_width = mirror,
    rack_width = rack,
    stages_width = stage,
    side_rows = side,
    rack_rows = rack_rows_for(side),
    stage_rows = stage_rows_for(side, quest_rows),
    quest_rows = quest_rows,
    body_width = width,
    stage_width = stage_width,
    indent = math.max(0, math.floor((model.width - stage_width) / 2)),
  }
end

-- every way the dressing room can stand, the one it is known for first
local SHAPES = { "between", "aside", "above" }

--- Decides how big everything is for a window: the mirror, both columns and the call sheet. The
--- mirror stands between the columns whenever it can be comfortably tall there, otherwise every
--- shape is tried and the one where the portrait stands tallest wins.
---@param model table needs width, height and portrait, figure when the image is a whole figure
---@return table plan { shape, portrait?, stacked, mirror_width, rack_width, stages_width, side_rows, rack_rows, stage_rows, quest_rows, body_width, stage_width, indent }
function M.plan(model)
  local plans = vim.tbl_map(function(shape)
    return shape_plan(model, shape)
  end, SHAPES)
  local between = plans[1]
  if between.portrait and between.portrait.height >= M.PORTRAIT.comfort then
    return between
  end
  return hud.biggest_portrait(plans) or between
end

-- frames ----------------------------------------------------------------------------------

local function frame_hl(focused)
  return focused and "EldenHudFrameSel" or "EldenHudFrame"
end

-- the top edge with its title on the left and a note on the right, like how many pieces it holds
local function top_edge(title, note, width, focused)
  local label = " " .. hud.fit(title, width - 8) .. " "
  local tail = (note and note ~= "") and (" " .. note .. " ") or ""
  local fill = width - 4 - vim.api.nvim_strwidth(label) - vim.api.nvim_strwidth(tail)
  return {
    { "╭─", frame_hl(focused) },
    { label, focused and "EldenHudTitle" or "EldenHudSection" },
    { ("─"):rep(math.max(0, fill)), frame_hl(focused) },
    { tail, "EldenHudCount" },
    { "─╮", frame_hl(focused) },
  }
end

local function bottom_edge(note, width, focused)
  local tail = (note and note ~= "") and (" " .. note .. " ") or ""
  return {
    {
      "╰" .. ("─"):rep(math.max(0, width - 3 - vim.api.nvim_strwidth(tail))),
      frame_hl(focused),
    },
    { tail, "EldenHudDim" },
    { "─╯", frame_hl(focused) },
  }
end

-- one row inside a frame, cut or padded to the frame's inner width
local function framed(chunks, width, focused)
  local inner = width - 4
  local row = { { "│ ", frame_hl(focused) } }
  vim.list_extend(row, hud.pad_chunks(hud.clip(chunks, inner), inner))
  table.insert(row, { " │", frame_hl(focused) })
  return row
end

-- the rack and the stages ------------------------------------------------------------------

local function label_chunks(item, width, selected, bg)
  local name_hl = selected and "EldenHudBanner" or "EldenHudName"
  local label = item.slot or item.name
  if not item.branch then
    return { { hud.pad(label, width), name_hl, bg = bg } }
  end
  local name_width = math.min(vim.api.nvim_strwidth(label) + 1, math.ceil(width * 0.55))
  return {
    { hud.pad(label, name_width), name_hl, bg = bg },
    { hud.pad(" " .. item.branch, width - name_width), "EldenHudDesc", bg = bg },
  }
end

local function list_row(item, selected, width)
  local bg = selected and "EldenHudSlotSel" or nil
  local count = item.count and tostring(item.count) or ""
  local row = {
    { selected and "▸ " or "  ", "EldenHudFrameSel", bg = bg },
    { hud.pad(item.key or "", 2), "EldenHudKey", bg = bg },
    {
      hud.pad(vim.trim(item.icon or "·"), 2),
      item.icon_hl or "EldenHudIcon",
      bg = bg,
      spot = selected and "cursor" or nil,
    },
    { " ", bg = bg },
  }
  local label_width = width - M.ROW_PREFIX - (count == "" and 0 or #count + 1)
  vim.list_extend(row, label_chunks(item, label_width, selected, bg))
  if count ~= "" then
    table.insert(row, { " ", bg = bg })
    table.insert(row, { count, "EldenHudCount", bg = bg })
  end
  return row
end

local function list_line(list, index, cursor, focused)
  local item = list.items[index]
  if item then
    return list_row(item, focused and index == cursor, list.width - 4)
  end
  if index == 1 then
    return { { list.empty, "EldenHudDim" } }
  end
  return {}
end

---@param list { focus: string, title: string, items: table[], width: integer, rows: integer, empty: string }
local function list_box(model, list)
  local cursor = model.cursor[list.focus] or 1
  local offset = hud.scroll(cursor - 1, list.rows, model.offset[list.focus] or 0)
  local focused = model.focus == list.focus
  local count = #list.items > 0 and tostring(#list.items) or ""
  local title = top_edge(list.title, count, list.width, focused)
  if list.focus == "items" then
    title[2].spot = "fallback"
  end
  local rows = { title }
  for index = offset + 1, offset + list.rows do
    table.insert(rows, framed(list_line(list, index, cursor, focused), list.width, focused))
  end
  local below = #list.items - offset - list.rows
  table.insert(rows, bottom_edge(below > 0 and ("▼ " .. below) or "", list.width, focused))
  return rows, { columns = 1, count = #list.items, offset = offset, cursor_row = cursor - 1 }
end

local function close_up(model, width)
  local item = parts.selected(model)
  local lines = item and hud.wrap(item.desc or "", width - 4) or {}
  local rows = { top_edge(model.examine or "Close up", nil, width, false) }
  table.insert(rows, framed({ { item and item.name or "", "EldenHudName" } }, width, false))
  for index = 1, M.CLOSE_UP_ROWS - 1 do
    table.insert(rows, framed({ { lines[index] or "", "EldenHudDesc" } }, width, false))
  end
  table.insert(rows, bottom_edge("", width, false))
  return rows
end

-- the call sheet's head: the project and how much changed, the branch whole on the next line
local function sheet_head(model, width)
  local status = model.status or {}
  if not status.project then
    local fallback = "No quest here, p travels to one of your " .. (model.sites or "projects")
    return { { { hud.fit(fallback, width), "EldenHudDim" } }, {} }
  end
  local count = status.changes and #status.changes or nil
  local tally = count == nil and "counting…" or count == 0 and "clean" or (count .. " changed")
  local dot = count and count > 0 and "EldenHudKey" or "EldenHudDim"
  local name_width = width - 5 - vim.api.nvim_strwidth(tally)
  return {
    {
      { "󰊢 ", "EldenHudIcon" },
      { hud.pad(status.project, name_width), "EldenHudBanner" },
      { " ● ", dot },
      { tally, "EldenHudCount" },
    },
    { { " ", "EldenHudKey" }, { hud.fit(status.branch or "?", width - 2), "EldenHudName" } },
  }
end

local function sheet_last(model, width)
  local status = model.status or {}
  if not status.last_file then
    return {}
  end
  local selected = parts.quest_selection(model)
  local bg = selected and "EldenHudSlotSel" or nil
  return {
    { selected and "▸ " or "  ", "EldenHudFrameSel" },
    { "󰘍 last  ", "EldenHudDim", bg = bg, spot = selected and "cursor" or nil },
    {
      hud.fit(status.last_file, width - 10),
      selected and "EldenHudBanner" or "EldenHudName",
      bg = bg,
    },
  }
end

-- the quest you left open, framed like a call sheet: the head, the last file and the changes
local function call_sheet(model, plan, width)
  local focused = model.focus == "quest"
  local inner = width - 4
  local label = focused and "Current Quest ▼" or "Current Quest  j"
  local rows = { top_edge(label, nil, width, focused) }
  for _, line in ipairs(sheet_head(model, inner)) do
    table.insert(rows, framed(line, width, focused))
  end
  table.insert(rows, framed(sheet_last(model, inner), width, focused))
  -- a card narrower than two readable paths lists the changed files in one column
  local change_columns = inner - 4 >= 2 * M.CHANGE_COLUMN and 2 or 1
  local _, change = parts.quest_selection(model)
  local changes = parts.changes(
    (model.status or {}).changes or {},
    inner - 2,
    plan.quest_rows,
    change,
    change_columns
  )
  for index = 1, plan.quest_rows do
    table.insert(rows, framed(hud.indent({ changes[index] or {} }, 2)[1], width, focused))
  end
  table.insert(rows, bottom_edge("", width, focused))
  return rows
end

local function columns(model, plan)
  local rack, rack_grid = list_box(model, {
    focus = "items",
    title = model.tabs[model.tab].title,
    items = model.tabs[model.tab].items,
    width = plan.rack_width,
    rows = plan.rack_rows,
    empty = "Nothing on the rack yet",
  })
  vim.list_extend(rack, close_up(model, plan.rack_width))
  local stages, stage_grid = list_box(model, {
    focus = "chest",
    title = model.chest.title,
    items = model.chest.items,
    width = plan.stages_width,
    rows = plan.stage_rows,
    empty = "No stage found yet",
  })
  vim.list_extend(stages, call_sheet(model, plan, plan.stages_width))
  return rack, stages, { items = rack_grid, chest = stage_grid }
end

-- the mirror ------------------------------------------------------------------------------

local function bulb_row(width)
  local bulbs = vim.fn.strcharpart((M.BULB .. " "):rep(math.ceil(width / 2)), 0, width)
  return { { bulbs, "EldenHudBulb" } }
end

local function mirror(model, plan)
  local portrait, width = plan.portrait, plan.mirror_width
  local right_pad = width - portrait.width - M.MIRROR_COLS
  local rows = { bulb_row(width) }
  for row = 1, portrait.height do
    -- every other row carries a bulb, so the sides read as a ring and not as a wall
    local bulb = row % 2 == 0 and M.BULB or " "
    table.insert(rows, {
      { bulb, "EldenHudBulb" },
      { " " },
      { "", spot = row == 1 and "portrait" or nil },
      { (" "):rep(portrait.width + 1 + right_pad) },
      { bulb, "EldenHudBulb" },
    })
  end
  table.insert(rows, bulb_row(width))
  table.insert(rows, { { ("▀"):rep(width), "EldenHudDesk" } })
  table.insert(
    rows,
    hud.center({ { parts.champion_name(model.character or "", width), "EldenHudTitle" } }, width)
  )
  table.insert(rows, hud.center({ { hud.fit(model.area or "", width), "EldenHudSection" } }, width))
  return rows
end

-- the sign and the rail ------------------------------------------------------------------

local function sign(model, width)
  local hub = require("core.banner.actions").spaced(model.hub or "")
  local bulbs = vim.trim((M.BULB .. " "):rep(3))
  local inner = vim.api.nvim_strwidth(hub) + 2 * vim.api.nvim_strwidth(bulbs) + 8
  local rows = {
    { { "╭" .. ("─"):rep(inner) .. "╮", "EldenHudFrameSel" } },
    {
      { "│ ", "EldenHudFrameSel" },
      { bulbs, "EldenHudBulb" },
      { "   " .. hub .. "   ", "EldenHudTitle" },
      { bulbs, "EldenHudBulb" },
      { " │", "EldenHudFrameSel" },
    },
    { { "╰" .. ("─"):rep(inner) .. "╯", "EldenHudFrameSel" } },
  }
  return vim.tbl_map(function(row)
    return hud.center(row, width)
  end, rows)
end

-- the tabs hang from a rail as tags, the active one from a heavier hook
local function rail(model, width)
  local half = math.floor(M.TAB_WIDTH / 2)
  local rail_row = { { "╓─", "EldenHudRule" } }
  local tags = { { "  " } }
  for index, tab in ipairs(model.tabs) do
    local active = index == model.tab
    table.insert(rail_row, {
      ("─"):rep(half) .. (active and "┳" or "┬") .. ("─"):rep(M.TAB_WIDTH - half - 1),
      active and "EldenHudRuleSel" or "EldenHudRule",
    })
    table.insert(tags, { (" "):rep(half - 1) })
    table.insert(tags, {
      (active and "┗" or "╰") .. hud.pad(vim.trim(tab.icon), 1) .. (active and "┛" or "╯"),
      active and "EldenHudTabSel" or "EldenHudTab",
    })
    table.insert(tags, { (" "):rep(M.TAB_WIDTH - half - 2) })
  end
  local used = 2 + #model.tabs * M.TAB_WIDTH
  table.insert(rail_row, { ("─"):rep(math.max(0, width - used - 1)) .. "╖", "EldenHudRule" })
  local position = ("%d / %d"):format(model.tab, #model.tabs)
  table.insert(tags, { (" "):rep(math.max(1, width - used - #position - 1)) })
  table.insert(tags, { position, "EldenHudDim" })
  return { rail_row, tags }
end

-- most important first, a narrow screen drops them from the end
local HINTS =
  { "⏎ Use", "K Check", "C Combine", "⇥ Tabs", "hjkl Move", "j Quest", "s Session", "q Quit" }

local function sides(model, plan)
  local rack, stages, grids = columns(model, plan)
  if plan.shape ~= "between" then
    return hud.beside(rack, plan.rack_width, stages, M.GAP), grids
  end
  local mirror_rows = mirror(model, plan)
  local height = math.max(#mirror_rows, plan.side_rows)
  local right = hud.beside(
    hud.middle(mirror_rows, height),
    plan.mirror_width,
    hud.middle(stages, height),
    M.GAP
  )
  return hud.beside(hud.middle(rack, height), plan.rack_width, right, M.GAP), grids
end

local function body(model, plan)
  local width = plan.body_width
  local rows = sign(model, width)
  table.insert(rows, {})
  vim.list_extend(rows, rail(model, width))
  table.insert(rows, {})
  local side_rows, grids = sides(model, plan)
  vim.list_extend(rows, side_rows)
  table.insert(rows, {})
  local hints = hud.hint_chunks(HINTS, width, "EldenHudKey", "EldenHudHint")
  table.insert(rows, hud.center(hints, width))
  return rows, grids
end

-- the mirror above or aside the whole body, when it does not stand between the columns
local function place_mirror(model, plan, rows)
  if plan.shape == "above" then
    local left = math.floor((plan.body_width - plan.mirror_width) / 2)
    local placed = hud.indent(mirror(model, plan), left)
    table.insert(placed, {})
    return vim.list_extend(placed, rows)
  end
  if plan.shape == "aside" then
    local column = mirror(model, plan)
    local height = math.max(#column, #rows)
    return hud.beside(
      hud.middle(column, height),
      plan.mirror_width,
      hud.middle(rows, height),
      M.GAP
    )
  end
  return rows
end

--- Lays out the whole dressing room for a model.
---@param model table HUD state: tabs, tab, focus, cursor, offset, chest, status, message, width, height
---@return table view { lines, marks, cursor, grids, anchors, plan }
function M.render(model)
  local plan = M.plan(model)
  local rows, grids = body(model, plan)
  grids.quest = {
    columns = 1,
    count = parts.quest_count(model.status or {}, plan.quest_rows),
    offset = 0,
    cursor_row = (model.cursor.quest or 1) - 1,
  }
  rows = place_mirror(model, plan, rows)
  vim.list_extend(rows, parts.footer(model, plan.stage_width))
  local lines, marks, spots = hud.compose(hud.indent(rows, plan.indent))
  local cursor = spots.cursor or spots.fallback
  local anchors = {}
  if plan.portrait and spots.portrait then
    anchors.portrait = vim.tbl_extend("force", spots.portrait, plan.portrait)
  end
  return {
    lines = lines,
    marks = marks,
    grids = grids,
    anchors = anchors,
    plan = plan,
    cursor = { row = cursor.row + 1, col = cursor.col },
  }
end

return M
