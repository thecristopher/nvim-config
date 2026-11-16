-- Elizabeth's dressing room, with her at center stage: her whole figure in a vanity mirror ringed
-- with bulbs over a dressing table with her name, as tall as the screen allows. On its left the
-- clothes rail the tabs hang from as tags, over the rack of the tab's pieces and a close up of the
-- selected one under a soft spotlight; on its right the marquee sign over the stages and the call
-- sheet of the quest you left open (scene, cast, location and call time). Everything sits centered
-- on screen at any size. Pure: model in, rows out.
local hud = require("core.hud.actions")
local parts = require("core.hud.views.parts")

local M = {}

M.MARGIN = 2
M.GAP = 3
M.TAB_WIDTH = { min = 4, max = 6 }
-- compact is how narrow a column may get when the mirror stands aside everything, center is how
-- narrow it may get beside the mirror at center stage (the stages hold the sign, so they need more)
M.RACK_WIDTH = { compact = 22, center = 34, max = 44 }
M.STAGE_WIDTH = { compact = 26, center = 45, max = 50 }
-- she is the star: the mirror takes center stage while its portrait stands at least this share of
-- the tallest one any shape allows
M.PORTRAIT = { min = 4, max = 36 }
M.CENTER_SHARE = 0.85
-- the photo stands this share of the rows its shape leaves, so it weighs on the screen like the
-- other franchises' portraits and is never stretched past the pixels it has
M.PORTRAIT_SHARE = 0.7
-- the bulbs ring the portrait: a bulb and a space on each side, a row of bulbs above and below
M.MIRROR_COLS = 4
M.MIRROR_ROWS = 2
-- under the mirror: the dressing table, the character's name and the stage
M.NAME_ROWS = 3
M.QUEST_CHANGE_ROWS = 3
-- above the columns the sign, a gap, the rail and its tags and a gap; under them a gap and the hints
M.TOP_ROWS = 7
M.BOTTOM_ROWS = 2
-- at center stage the rail tops the rack (rail, tags, gap) and the sign tops the stages (sign, gap)
M.RAIL_ROWS = 3
M.SIGN_ROWS = 4
-- the close up card holds the piece's name and two lines about it
M.CLOSE_UP_ROWS = 3
-- the columns grow no taller than this, so a tall mirror is flanked by cabinets, not empty towers
M.SIDE_MAX = { beside = 22, center = 30 }
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

-- the rack's frame, the close up card and, at center stage, the rail above them
local function rack_rows_for(side, center)
  return side - 2 - (M.CLOSE_UP_ROWS + 2) - (center and M.RAIL_ROWS or 0)
end

-- the call sheet's head: scene, cast, location and call, one row each
M.SHEET_ROWS = 4
-- the labels of the call sheet line up their values after this many cells
M.SHEET_LABEL = 10

-- the stages' frame and the call sheet: its top edge, its head, the last file, the changes and its
-- bottom edge, and at center stage the sign above them
local function stage_rows_for(side, quest_rows, center)
  return side - 2 - (2 + M.SHEET_ROWS + quest_rows + 1) - (center and M.SIGN_ROWS or 0)
end

-- the shortest columns that still show three pieces and two stages
local function side_min(quest_rows, center)
  local rack = 3 + 2 + M.CLOSE_UP_ROWS + 2 + (center and M.RAIL_ROWS or 0)
  local stages = 2 + 2 + 2 + M.SHEET_ROWS + quest_rows + 1 + (center and M.SIGN_ROWS or 0)
  return math.max(rack, stages)
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
---@param size "compact"|"center" the narrowest each column may get
local function column_widths(space, size)
  local rack = hud.clamp(math.floor((space - M.GAP) * 0.45), M.RACK_WIDTH[size], M.RACK_WIDTH.max)
  local stage = hud.clamp(space - M.GAP - rack, M.STAGE_WIDTH[size], M.STAGE_WIDTH.max)
  return rack, stage
end

-- the cells and rows a shape leaves the portrait: at center stage between the columns as tall as
-- the screen, aside the whole body, or above it
local function mirror_room(shape, inner, room, quest_rows)
  local ring = M.MIRROR_ROWS + M.NAME_ROWS
  -- one more cell for the padding an even width gets
  local cols = M.MIRROR_COLS + 1
  if shape == "center" then
    local columns = body_width(M.RACK_WIDTH.center, M.STAGE_WIDTH.center)
    return inner - columns - 2 * M.GAP - cols, room - M.BOTTOM_ROWS - ring
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
  local tallest = math.min(math.floor(height * M.PORTRAIT_SHARE), M.PORTRAIT.max)
  return hud.portrait_fit(width, tallest, M.PORTRAIT.min, ratio)
end

-- how tall both columns stand: as tall as the mirror beside them up to SIDE_MAX, or what the
-- room leaves
local function side_for(shape, portrait, room, quest_rows)
  if shape == "center" then
    local low = side_min(quest_rows, true)
    return hud.clamp(mirror_height(portrait), low, math.max(low, M.SIDE_MAX.center))
  end
  local low = side_min(quest_rows)
  local above = shape == "above" and mirror_height(portrait) + 1 or 0
  return hud.clamp(room - fixed_rows() - above, low, M.SIDE_MAX.beside)
end

-- the width the columns leave beside the mirror, by where the mirror stands
local function columns_space(shape, inner, mirror)
  if shape == "center" then
    return inner - mirror - M.GAP
  end
  if shape == "aside" then
    return inner - mirror - M.GAP
  end
  return inner
end

-- the tags share the rail, narrower when there are many tabs on a narrow rack
local function tab_width(model, width)
  local tabs = math.max(1, #(model.tabs or {}))
  return hud.clamp(math.floor((width - 4) / tabs), M.TAB_WIDTH.min, M.TAB_WIDTH.max)
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
  local center = placed == "center"
  local mirror = portrait and mirror_width(portrait) or 0
  local rack, stage =
    column_widths(columns_space(placed, inner, mirror), center and "center" or "compact")
  local width = body_width(rack, stage) + (center and mirror + M.GAP or 0)
  local stage_width = width + (placed == "aside" and mirror + M.GAP or 0)
  local side = side_for(placed, portrait, room, quest_rows)
  return {
    shape = placed,
    portrait = portrait,
    stacked = placed == "above",
    mirror_width = mirror,
    rack_width = rack,
    stages_width = stage,
    tab_width = tab_width(model, center and rack or width),
    side_rows = side,
    rack_rows = rack_rows_for(side, center),
    stage_rows = stage_rows_for(side, quest_rows, center),
    quest_rows = quest_rows,
    body_width = width,
    stage_width = stage_width,
    indent = math.max(0, math.floor((model.width - stage_width) / 2)),
  }
end

-- every way the dressing room can stand, the one it is known for first
local SHAPES = { "center", "aside", "above" }

--- Decides how big everything is for a window. She is the star: every shape is tried, and the
--- mirror takes center stage between the columns as long as its portrait stands at least
--- CENTER_SHARE of the tallest one, otherwise the shape where it stands tallest wins.
---@param model table needs width, height and portrait, figure when the image is a whole figure
---@return table plan { shape, portrait?, stacked, mirror_width, rack_width, stages_width, tab_width, side_rows, rack_rows, stage_rows, quest_rows, body_width, stage_width, indent }
function M.plan(model)
  local plans = vim.tbl_map(function(shape)
    return shape_plan(model, shape)
  end, SHAPES)
  local center, best = plans[1], hud.biggest_portrait(plans) or plans[1]
  local tallest = best.portrait and best.portrait.height or 0
  if center.portrait and center.portrait.height >= tallest * M.CENTER_SHARE then
    return center
  end
  return best
end

-- frames ----------------------------------------------------------------------------------

local function frame_hl(focused)
  return focused and "EldenHudFrameSel" or "EldenHudFrame"
end

-- the top edge with its title on the left and a note on the right, like how many pieces it holds
local function top_edge(title, note, width, focused)
  local label = " " .. hud.fit_name(title, width - 8) .. " "
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

-- one name column for a whole list, so every branch starts at the same cell: as wide as the
-- longest name, since a name always shows whole before any branch does
local function name_column(items, width)
  local longest = 0
  for _, item in ipairs(items) do
    longest = math.max(longest, vim.api.nvim_strwidth(item.slot or item.name))
  end
  return math.min(longest + 1, width)
end

local function label_chunks(item, width, selected, bg, name_width)
  local name_hl = selected and "EldenHudBanner" or "EldenHudName"
  local label = item.slot or item.name
  if not item.branch then
    return { { hud.pad(hud.fit_name(label, width), width), name_hl, bg = bg } }
  end
  name_width = math.min(name_width or (vim.api.nvim_strwidth(label) + 1), width)
  -- the branch shows where it breaks, or not at all
  local branch = hud.fit_words(item.branch, width - name_width - 1)
  return {
    { hud.pad(hud.fit_name(label, name_width), name_width), name_hl, bg = bg },
    { hud.pad(branch and (" " .. branch) or "", width - name_width), "EldenHudDesc", bg = bg },
  }
end

-- the spotlight: the selected piece in full light, the ones beside it in its spill
local function spot_bg(selected, near)
  if selected then
    return "EldenHudSlotSel"
  end
  return near and "EldenHudSpotNear" or nil
end

local function list_row(item, selected, width, near, name_width)
  local bg = spot_bg(selected, near)
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
  -- the count steps aside before the name would be cut
  local label = item.slot or item.name
  if count ~= "" and vim.api.nvim_strwidth(label) > width - M.ROW_PREFIX - #count - 1 then
    count = ""
  end
  local label_width = width - M.ROW_PREFIX - (count == "" and 0 or #count + 1)
  local label_column = name_width and math.min(name_width, label_width) or nil
  vim.list_extend(row, label_chunks(item, label_width, selected, bg, label_column))
  if count ~= "" then
    table.insert(row, { " ", bg = bg })
    table.insert(row, { count, "EldenHudCount", bg = bg })
  end
  return row
end

local function list_line(list, index, cursor, focused)
  local item = list.items[index]
  if item then
    local near = focused and math.abs(index - cursor) == 1
    local width = list.width - 4
    local names = name_column(list.items, width - M.ROW_PREFIX)
    return list_row(item, focused and index == cursor, width, near, names)
  end
  -- an empty list says so across its first rows, whole or not at all
  local empty = hud.wrap_whole(list.empty, list.width - 4, list.rows) or {}
  if #list.items == 0 and empty[index] then
    return { { empty[index], "EldenHudDim" } }
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
  local lines = hud.reveal(
    item and hud.wrap_rows(item.desc or "", width - 4, M.CLOSE_UP_ROWS - 1) or {},
    model.typed
  )
  local rows = { top_edge(model.examine or "Close up", nil, width, false) }
  local name = item and hud.fit_name(item.name, width - 4) or ""
  table.insert(rows, framed({ { name, "EldenHudName" } }, width, false))
  for index = 1, M.CLOSE_UP_ROWS - 1 do
    table.insert(rows, framed({ { lines[index] or "", "EldenHudDesc" } }, width, false))
  end
  table.insert(rows, bottom_edge("", width, false))
  return rows
end

-- what the call sheet calls each of its lines, in the world's words
local SHEET_LABELS = { scene = "SCENE", cast = "CAST", location = "LOCATION", call = "CALL" }

local function sheet_label(model, key)
  return ((model.hud or {}).stats or {})[key] or SHEET_LABELS[key]
end

-- a line of the call sheet: its label and the first of the value's forms that fits whole, a name
-- cut where it breaks as the last resort
local function sheet_line(model, key, forms, hl, width)
  local room = width - M.SHEET_LABEL
  local value = hud.first_fit(forms, room) or hud.fit_name(forms[1] or "·", room)
  return {
    { hud.pad(sheet_label(model, key), M.SHEET_LABEL), "EldenHudDim" },
    { value, hl },
  }
end

-- the call time: when the session started and how much changed since, shortening to the time
-- alone before it would ever be cut
local function call_times(model)
  local status = model.status or {}
  local count = status.changes and #status.changes or nil
  local tally = count == nil and "counting…" or count == 0 and "clean" or (count .. " changed")
  if not model.session_start then
    return { tally }
  end
  return {
    ("since %s  ·  %s"):format(model.session_start, tally),
    "since " .. model.session_start,
    model.session_start,
  }
end

-- the call sheet's head: the scene is the branch, the cast the region's character, the location
-- the project and the call when the session began
local function sheet_head(model, width)
  local status = model.status or {}
  if not status.project then
    local rows = {}
    for _, line in ipairs(hud.wrap_whole(parts.word(model, "no_quest"), width, M.SHEET_ROWS) or {}) do
      table.insert(rows, { { line, "EldenHudDim" } })
    end
    while #rows < M.SHEET_ROWS do
      table.insert(rows, {})
    end
    return rows
  end
  local cast = model.character or status.character or "·"
  return {
    sheet_line(model, "scene", { status.branch or "·" }, "EldenHudBanner", width),
    sheet_line(model, "cast", { cast, cast:match("^%S+") }, "EldenHudName", width),
    sheet_line(model, "location", { status.project }, "EldenHudName", width),
    sheet_line(model, "call", call_times(model), "EldenHudCount", width),
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
      hud.fit_name(status.last_file, width - 10),
      selected and "EldenHudBanner" or "EldenHudName",
      bg = bg,
    },
  }
end

-- the quest you left open, framed like a call sheet: the head, the last file and the changes
local function call_sheet(model, plan, width)
  local focused = model.focus == "quest"
  local inner = width - 4
  local quest = parts.word(model, "quest")
  local label = focused and quest .. " ▼" or quest .. "  j"
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
    empty = parts.word(model, "empty"),
  })
  vim.list_extend(rack, close_up(model, plan.rack_width))
  local stages, stage_grid = list_box(model, {
    focus = "chest",
    title = model.chest.title,
    items = model.chest.items,
    width = plan.stages_width,
    rows = plan.stage_rows,
    empty = parts.word(model, "no_sites"),
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
  table.insert(rows, parts.whole_line(model.area, "EldenHudSection", width))
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
local function rail(model, width, tag_width)
  local half = math.floor(tag_width / 2)
  local rail_row = { { "╓─", "EldenHudRule" } }
  local tags = { { "  " } }
  for index, tab in ipairs(model.tabs) do
    local active = index == model.tab
    table.insert(rail_row, {
      ("─"):rep(half) .. (active and "┳" or "┬") .. ("─"):rep(tag_width - half - 1),
      active and "EldenHudRuleSel" or "EldenHudRule",
    })
    table.insert(tags, { (" "):rep(half - 1) })
    table.insert(tags, {
      (active and "┗" or "╰") .. hud.pad(vim.trim(tab.icon), 1) .. (active and "┛" or "╯"),
      active and "EldenHudTabSel" or "EldenHudTab",
    })
    table.insert(tags, { (" "):rep(tag_width - half - 2) })
  end
  local used = 2 + #model.tabs * tag_width
  table.insert(rail_row, { ("─"):rep(math.max(0, width - used - 1)) .. "╖", "EldenHudRule" })
  -- which tab out of how many, when the rail has room left for it
  local position = ("%d / %d"):format(model.tab, #model.tabs)
  if width - used >= #position + 2 then
    table.insert(tags, { (" "):rep(width - used - #position - 1) })
    table.insert(tags, { position, "EldenHudDim" })
  end
  return { rail_row, tags }
end

local function hint_row(model, width)
  -- most important first, a narrow screen drops them from the end
  local hints =
    hud.hint_chunks(parts.hints(model, parts.USE_HINTS), width, "EldenHudKey", "EldenHudHint")
  return hud.center(hints, width)
end

-- center stage: the rail tops the rack, the sign tops the stages, and the mirror stands between
-- them as tall as the screen allows, the columns centered beside it
local function center_stage(model, plan)
  local rack, stages, grids = columns(model, plan)
  local left = rail(model, plan.rack_width, plan.tab_width)
  table.insert(left, {})
  vim.list_extend(left, rack)
  local right = sign(model, plan.stages_width)
  table.insert(right, {})
  vim.list_extend(right, stages)
  local mirror_rows = mirror(model, plan)
  local height = math.max(#mirror_rows, #left, #right)
  local inner =
    hud.beside(hud.middle(mirror_rows, height), plan.mirror_width, hud.middle(right, height), M.GAP)
  local rows = hud.beside(hud.middle(left, height), plan.rack_width, inner, M.GAP)
  table.insert(rows, {})
  table.insert(rows, hint_row(model, plan.body_width))
  return rows, grids
end

-- the sign over the rail over both columns, for the shapes where the mirror stands elsewhere
local function stacked_body(model, plan)
  local width = plan.body_width
  local rows = sign(model, width)
  table.insert(rows, {})
  vim.list_extend(rows, rail(model, width, plan.tab_width))
  table.insert(rows, {})
  local rack, stages, grids = columns(model, plan)
  vim.list_extend(rows, hud.beside(rack, plan.rack_width, stages, M.GAP))
  table.insert(rows, {})
  table.insert(rows, hint_row(model, width))
  return rows, grids
end

local function body(model, plan)
  if plan.shape == "center" then
    return center_stage(model, plan)
  end
  return stacked_body(model, plan)
end

-- the mirror above or aside the whole body, when it does not take center stage
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
