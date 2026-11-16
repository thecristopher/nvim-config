-- The Elden Ring hub: the champion's portrait standing tall beside the inventory, the runes held in
-- the corner. Category tabs, the Inventory grid with every item named and a glint running along the
-- selected frame, the Sites of Grace with their branch and changes, the selected item laid out like
-- the game's item screen (its name, its category, its effect and a line of lore in italics), the
-- champion's attributes and the quest you left open. Everything sits centered on screen at any size.
-- Pure: model in, rows out.
local hud = require("core.hud.actions")
local parts = require("core.hud.views.parts")

local M = {}

M.MARGIN = 2
M.GAP = 4
M.PANE_GAP = 3
M.SLOT_WIDTH = 16
M.SLOT_HEIGHT = 4
M.TAB_WIDTH = 5
M.CHEST_WIDTH = { min = 36, max = 52 }
M.COLUMNS = { min = 2, max = 4 }
-- comfort is the fewest rows the grid keeps before the quest's changes give theirs up
M.GRID_ROWS = { min = 1, comfort = 2, max = 4 }
M.PORTRAIT = { min = 4, max = 36 }
-- under a stacked portrait: the champion's name and a gap before the body
M.STACKED_ROWS = 2
-- under the portrait: a gap, the plaque (three rows), the area, a gap, the greeting and the date
M.PLAQUE_ROWS = 8
-- the attributes under the plaque: a gap and three rows of two columns, only when the portrait
-- already stands as tall as it can
M.ATTRIBUTE_ROWS = 4
-- narrower than this, the plaque writes the date short
M.SHORT_DATE_WIDTH = 30
M.QUEST_CHANGE_ROWS = 3
-- the detail band under the panes: a rule, the name and category, two rows of effect, the lore
-- and the hints
M.DETAIL_ROWS = 6

local FRAMES = {
  normal = {
    tl = "┌",
    tr = "┐",
    bl = "└",
    br = "┘",
    h = "─",
    v = "│",
    hl = "EldenHudFrame",
  },
  selected = {
    tl = "┏",
    tr = "┓",
    bl = "┗",
    br = "┛",
    h = "━",
    v = "┃",
    hl = "EldenHudFrameSel",
  },
}

-- sizes -----------------------------------------------------------------------------------

local function body_width(columns, chest_width)
  return columns * M.SLOT_WIDTH + M.PANE_GAP + chest_width
end

-- rows the body takes besides the grid: title and tabs, the panes' titles, the description, the quest
local function fixed_rows(quest_rows)
  return 5 + 1 + 1 + M.DETAIL_ROWS + 1 + 3 + quest_rows
end

-- every way the hub can stand: the portrait beside a body of two columns or more, beside a single
-- column, or above the body. The plan keeps the one with the biggest portrait
local SHAPES = {
  { beside = true, columns = M.COLUMNS.min },
  { beside = true, columns = 1 },
  { beside = false },
}

-- the portrait beside a body of that many columns, with the plaque under it
local function portrait_beside(inner, room, columns)
  return hud.portrait_fit(
    inner - M.GAP - body_width(columns, M.CHEST_WIDTH.min),
    math.min(room - M.PLAQUE_ROWS, M.PORTRAIT.max),
    M.PORTRAIT.min
  )
end

-- the portrait above the body, taking the rows the smallest body leaves
local function portrait_above(inner, room, quest_rows)
  local body_rows = fixed_rows(quest_rows) + M.GRID_ROWS.min * M.SLOT_HEIGHT
  return hud.portrait_fit(
    inner,
    math.min(room - body_rows - M.STACKED_ROWS, M.PORTRAIT.max),
    M.PORTRAIT.min
  )
end

-- the whole plan for one shape
local function shape_plan(model, shape)
  local inner = model.width - 2 * M.MARGIN
  local room = model.height - 2 - parts.FOOTER_ROWS
  local quest_rows = room - fixed_rows(M.QUEST_CHANGE_ROWS) >= M.SLOT_HEIGHT and M.QUEST_CHANGE_ROWS
    or 0
  local portrait = nil
  if model.portrait and shape.beside then
    portrait = portrait_beside(inner, room, shape.columns)
  elseif model.portrait then
    portrait = portrait_above(inner, room, quest_rows)
    -- the quest's changes give their rows up before the portrait does
    if not portrait and quest_rows > 0 then
      quest_rows = 0
      portrait = portrait_above(inner, room, quest_rows)
    end
  end
  local stacked = portrait ~= nil and not shape.beside
  local space = inner - ((portrait and not stacked) and portrait.width + M.GAP or 0)
  local columns = hud.clamp(
    math.floor((space - M.PANE_GAP - M.CHEST_WIDTH.max) / M.SLOT_WIDTH),
    M.COLUMNS.min,
    M.COLUMNS.max
  )
  if space < body_width(columns, M.CHEST_WIDTH.min) then
    columns = 1
  end
  local chest_width =
    hud.clamp(space - M.PANE_GAP - columns * M.SLOT_WIDTH, M.CHEST_WIDTH.min, M.CHEST_WIDTH.max)
  local above = stacked and portrait.height + M.STACKED_ROWS or 0
  local function grid_rows_with(rows)
    return hud.clamp(
      math.floor((room - above - fixed_rows(rows)) / M.SLOT_HEIGHT),
      M.GRID_ROWS.min,
      M.GRID_ROWS.max
    )
  end
  local grid_rows = grid_rows_with(quest_rows)
  -- the quest's changes also give their rows up before the inventory shrinks under its comfort
  if quest_rows > 0 and grid_rows < M.GRID_ROWS.comfort and grid_rows_with(0) > grid_rows then
    quest_rows = 0
    grid_rows = grid_rows_with(0)
  end
  local stage_width = ((portrait and not stacked) and portrait.width + M.GAP or 0)
    + body_width(columns, chest_width)
  -- the attributes stand under the plaque only in the rows the portrait leaves over
  -- and only when every label and value fits whole beside its pair
  local attributes = model.attributes ~= nil
    and portrait ~= nil
    and not stacked
    and room - M.PLAQUE_ROWS - portrait.height >= M.ATTRIBUTE_ROWS
    and hud.stat_rows_fit(model.attributes, portrait.width)
  return {
    portrait = portrait,
    stacked = stacked,
    attributes = attributes,
    columns = columns,
    chest_width = chest_width,
    grid_rows = grid_rows,
    quest_rows = quest_rows,
    body_width = body_width(columns, chest_width),
    stage_width = stage_width,
    indent = math.max(0, math.floor((model.width - stage_width) / 2)),
  }
end

--- Decides how big everything is for a window: the portrait, the grid's columns and rows.
--- The portrait comes first: every shape is tried and the one where it stands tallest wins.
---@param model table needs width, height and portrait
---@return table plan { portrait?, stacked, columns, chest_width, grid_rows, quest_rows, body_width, stage_width, indent }
function M.plan(model)
  if not model.portrait then
    return shape_plan(model, SHAPES[1])
  end
  return hud.biggest_portrait(vim.tbl_map(function(shape)
    return shape_plan(model, shape)
  end, SHAPES))
end

-- the inventory ---------------------------------------------------------------------------

local function slot_line(frame, inner, text, hl, bg, spot)
  local left = math.floor((inner - vim.api.nvim_strwidth(text)) / 2)
  return {
    { frame.v, frame.hl },
    { (" "):rep(left), bg = bg },
    { text, hl, bg = bg, spot = spot },
    { (" "):rep(inner - left - vim.api.nvim_strwidth(text)), bg = bg },
    { frame.v, frame.hl },
  }
end

-- the cell the glint lights along a frame of this width, nil when no glint runs
local function glint_cell(glint, width)
  if not glint then
    return nil
  end
  return math.floor(glint * (width + 2)) - 1
end

local function slot(item, selected, glint)
  local frame = selected and FRAMES.selected or FRAMES.normal
  local inner = M.SLOT_WIDTH - 2
  local bg = selected and "EldenHudSlotSel" or nil
  local key = item.key or ""
  local count = item.count and tostring(item.count) or ""
  local icon = hud.fit(vim.trim(item.icon or "·"), 2)
  local name = hud.fit_name(item.slot or item.name, inner - 2)
  -- the glint runs left to right along the top edge and back along the bottom one
  local at = selected and glint_cell(glint, M.SLOT_WIDTH) or nil
  local top = { { frame.tl, frame.hl }, { key, "EldenHudKey" } }
  vim.list_extend(
    top,
    hud.glint_run(
      frame.h:rep(inner - #key) .. frame.tr,
      frame.hl,
      at and at - 1 - #key,
      "EldenHudGlint"
    )
  )
  local bottom = hud.glint_run(
    frame.bl .. frame.h:rep(inner - 1 - #count),
    frame.hl,
    at and (M.SLOT_WIDTH - 1 - at),
    "EldenHudGlint"
  )
  vim.list_extend(bottom, { { count, "EldenHudCount" }, { frame.h .. frame.br, frame.hl } })
  return {
    top,
    slot_line(frame, inner, icon, item.icon_hl or "EldenHudIcon", bg, selected and "cursor" or nil),
    slot_line(frame, inner, name, selected and "EldenHudName" or "EldenHudDesc", bg),
    bottom,
  }
end

local function grid(items, cursor, focused, columns, offset, visible, glint)
  local rows = {}
  local last_row = math.ceil(#items / columns) - 1
  for grid_row = offset, math.min(offset + visible - 1, last_row) do
    local band = { {}, {}, {}, {} }
    for col = 1, columns do
      local index = grid_row * columns + col
      if items[index] then
        for line, chunks in ipairs(slot(items[index], focused and index == cursor, glint)) do
          vim.list_extend(band[line], chunks)
        end
      end
    end
    vim.list_extend(rows, band)
  end
  return rows
end

local function inventory(model, plan)
  local items = model.tabs[model.tab].items
  local focused = model.focus == "items"
  local cursor_row = math.floor(((model.cursor.items or 1) - 1) / plan.columns)
  local offset = hud.scroll(cursor_row, plan.grid_rows, model.offset.items or 0)
  local rows = { { { parts.word(model, "inventory"), "EldenHudSection", spot = "fallback" } } }
  vim.list_extend(
    rows,
    grid(items, model.cursor.items, focused, plan.columns, offset, plan.grid_rows, model.glint)
  )
  if #items == 0 then
    table.insert(rows, { { parts.word(model, "empty"), "EldenHudDim" } })
  end
  return rows, { columns = plan.columns, count = #items, offset = offset, cursor_row = cursor_row }
end

-- the chest: Sites of Grace as a list, so every project keeps its full name and branch ------

-- the marker, key, icon and count take 14 cells, names share the rest with branches, one column for all
local function name_column(items, width)
  local longest = 0
  for _, item in ipairs(items) do
    longest = math.max(longest, vim.api.nvim_strwidth(item.name))
  end
  return math.min(longest + 2, math.ceil((width - 14) * 0.55))
end

local function chest_row(item, selected, width, name_width)
  local bg = selected and "EldenHudSlotSel" or nil
  local count = item.count and ("● " .. item.count) or ""
  local rest = width - 14
  return {
    { selected and "▶ " or "  ", "EldenHudFrameSel", bg = bg },
    { hud.pad(item.key or "", 2), "EldenHudKey", bg = bg },
    {
      hud.pad(vim.trim(item.icon or ""), 2),
      item.icon_hl or "EldenHudIcon",
      bg = bg,
      spot = selected and "cursor" or nil,
    },
    { " ", bg = bg },
    {
      hud.pad(hud.fit_name(item.name, name_width), name_width),
      selected and "EldenHudBanner" or "EldenHudName",
      bg = bg,
    },
    -- the branch shows where it breaks, or not at all
    {
      hud.pad(
        item.branch and (" " .. (hud.fit_words(item.branch, rest - name_width - 2) or "")) or "",
        rest - name_width
      ),
      "EldenHudDesc",
      bg = bg,
    },
    { (" "):rep(7 - vim.api.nvim_strwidth(count)), bg = bg },
    { count, "EldenHudCount", bg = bg },
  }
end

local function chest(model, plan)
  local items = model.chest.items
  local visible = plan.grid_rows * M.SLOT_HEIGHT
  local cursor = model.cursor.chest or 1
  local offset = hud.scroll(cursor - 1, visible, model.offset.chest or 0)
  local rows = { { { model.chest.title, "EldenHudSection" } } }
  for index = offset + 1, math.min(offset + visible, #items) do
    table.insert(
      rows,
      chest_row(
        items[index],
        model.focus == "chest" and index == cursor,
        plan.chest_width,
        name_column(items, plan.chest_width)
      )
    )
  end
  if #items == 0 then
    table.insert(rows, { { parts.word(model, "no_sites"), "EldenHudDim" } })
  end
  return rows, { columns = 1, count = #items, offset = offset, cursor_row = cursor - 1 }
end

-- the rest of the body ----------------------------------------------------------------------

local function tab_bar(model)
  local bar, rule = { { "◁ ", "EldenHudDim" } }, { { "  " } }
  for index, tab in ipairs(model.tabs) do
    local active = index == model.tab
    table.insert(bar, {
      hud.pad("  " .. vim.trim(tab.icon), M.TAB_WIDTH),
      active and "EldenHudTabSel" or "EldenHudTab",
    })
    table.insert(rule, {
      (active and "━" or "─"):rep(M.TAB_WIDTH),
      active and "EldenHudRuleSel" or "EldenHudRule",
    })
  end
  table.insert(bar, { " ▷   ", "EldenHudDim" })
  table.insert(bar, { model.tabs[model.tab].title, "EldenHudTitle" })
  return bar, rule
end

-- the item screen of the game: the name with its category on the right, the effect, then a line of
-- lore in italics
local function description(model, item, width)
  local rows = { { { ("─"):rep(width), "EldenHudRule" } } }
  local lines = hud.reveal(item and hud.wrap_rows(item.desc or "", width - 2, 2) or {}, model.typed)
  local category = item and item.category and { { item.category, "EldenHudCategory" } } or {}
  table.insert(
    rows,
    hud.corner(
      { { " " .. (item and hud.fit_name(item.name, width - 2) or ""), "EldenHudName" } },
      vim.list_extend(category, { { " " } }),
      width
    )
  )
  for index = 1, 2 do
    table.insert(rows, { { " " .. (lines[index] or ""), "EldenHudDesc" } })
  end
  -- the lore reads whole or stays unsaid
  local flavor = item and item.flavor
  local fits = flavor and vim.api.nvim_strwidth(flavor) <= width - 4
  table.insert(rows, fits and { { "  " .. flavor, "EldenHudFlavor" } } or {})
  -- most important first, a narrow screen drops them from the end
  local hints =
    hud.hint_chunks(parts.hints(model, parts.USE_HINTS), width - 2, "EldenHudKey", "EldenHudHint")
  table.insert(rows, vim.list_extend({ { " ", "EldenHudHint" } }, hints))
  return rows
end

local function rule(label, width)
  local head = "◈── " .. label .. " "
  return {
    {
      head .. ("─"):rep(math.max(2, width - vim.api.nvim_strwidth(head) - 1)) .. "◈",
      "EldenHudSection",
    },
  }
end

local function quest(model, plan)
  return parts.quest(model, plan.body_width, plan.quest_rows, rule)
end

local function panes(model, plan)
  local inventory_rows, inventory_grid = inventory(model, plan)
  local chest_rows, chest_grid = chest(model, plan)
  local height = 1 + plan.grid_rows * M.SLOT_HEIGHT
  local rows = hud.beside(inventory_rows, plan.columns * M.SLOT_WIDTH, chest_rows, M.PANE_GAP)
  while #rows < height do
    table.insert(rows, {})
  end
  return rows, { items = inventory_grid, chest = chest_grid }
end

-- the hub's name in the middle and the runes held in the corner, like the game's own screen
local function title_row(model, width)
  local hub = require("core.banner.actions").spaced(model.hub or "")
  local purse = (model.status or {}).purse
  return hud.corner(
    hud.center({ { "◈   " .. hub .. "   ◈", "EldenHudTitle" } }, width),
    purse and { { purse, "EldenHudCount" } } or {},
    width
  )
end

local function body(model, plan)
  local width = plan.body_width
  local bar, tab_rule = tab_bar(model)
  local rows = {
    title_row(model, width),
    {},
    bar,
    tab_rule,
    {},
  }
  local pane_rows, grids = panes(model, plan)
  vim.list_extend(rows, pane_rows)
  table.insert(rows, {})
  vim.list_extend(rows, description(model, parts.selected(model), width))
  table.insert(rows, {})
  vim.list_extend(rows, quest(model, plan))
  return rows, grids
end

-- the champion ------------------------------------------------------------------------------

-- the greeting and the date at the foot of the plaque, always three rows. A long greeting takes
-- the gap above it and one that cannot fit whole in two rows stays unsaid; the date shortens to
-- the day and the hour, the day alone or the hour alone before it would ever be cut
local function salutation(model, width)
  local date = hud.first_fit({
    width >= M.SHORT_DATE_WIDTH and model.date or nil,
    model.date_short,
    model.date_day,
    model.clock,
  }, width)
  local greeting = hud.wrap_whole(model.greeting or "", width, 2) or {}
  local rows = {}
  if #greeting < 2 then
    table.insert(rows, {})
  end
  for _, line in ipairs(greeting) do
    table.insert(rows, hud.center({ { line, "EldenHudName" } }, width))
  end
  while #rows < 2 do
    table.insert(rows, {})
  end
  table.insert(rows, date and hud.center({ { date, "EldenHudDim" } }, width) or {})
  return rows
end

local function champion(model, plan)
  local portrait = plan.portrait
  local width = portrait.width
  local rows = { { { "", spot = "portrait" } } }
  for _ = 2, portrait.height do
    table.insert(rows, {})
  end
  local ornament = "◈" .. ("━"):rep(width - 2) .. "◈"
  vim.list_extend(rows, {
    {},
    { { ornament, "EldenHudTitle" } },
    hud.center({ { parts.champion_name(model.character or "", width), "EldenHudTitle" } }, width),
    { { ornament, "EldenHudTitle" } },
    parts.whole_line(model.area, "EldenHudSection", width),
  })
  vim.list_extend(rows, salutation(model, width))
  if plan.attributes then
    table.insert(rows, {})
    vim.list_extend(rows, hud.stat_rows(model.attributes, width))
  end
  return rows
end

-- the attributes in one line, for the footer when the plaque has no room left under them: whole
-- pairs only, the last ones left out when the row runs short
local function attribute_line(model, width)
  if not model.attributes then
    return nil
  end
  local chunks = {}
  for index, pair in ipairs(model.attributes) do
    local pair_chunks = {
      { (index > 1 and "   " or "") .. pair[1] .. " ", "EldenHudDim" },
      { pair[2], "EldenHudName" },
    }
    if hud.width(chunks) + hud.width(pair_chunks) > width then
      break
    end
    vim.list_extend(chunks, pair_chunks)
  end
  return #chunks > 0 and hud.center(chunks, width) or nil
end

-- the portrait centered above the body with the champion's name under it
local function champion_above(model, portrait, width)
  local left = math.floor((width - portrait.width) / 2)
  local rows = { { { (" "):rep(left) }, { "", spot = "portrait" } } }
  for _ = 2, portrait.height do
    table.insert(rows, {})
  end
  table.insert(
    rows,
    hud.center({ { parts.champion_name(model.character or "", width), "EldenHudTitle" } }, width)
  )
  table.insert(rows, {})
  return rows
end

--- Lays out the whole Elden Ring hub for a model.
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
  if plan.portrait and plan.stacked then
    rows = vim.list_extend(champion_above(model, plan.portrait, plan.body_width), rows)
  elseif plan.portrait then
    local column = champion(model, plan)
    local height = math.max(#column, #rows)
    rows =
      hud.beside(hud.middle(column, height), plan.portrait.width, hud.middle(rows, height), M.GAP)
  end
  local line = not plan.attributes and attribute_line(model, plan.stage_width) or nil
  vim.list_extend(rows, parts.footer(model, plan.stage_width, line))
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
