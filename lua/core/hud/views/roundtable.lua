-- The Elden Ring hub: the champion's portrait standing tall beside the inventory. Category tabs, the
-- Inventory grid with every item named, the Sites of Grace with their branch and changes, the selected
-- item described, and the quest you left open. Everything sits centered on screen at any size.
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
M.GRID_ROWS = { min = 1, max = 4 }
M.PORTRAIT = { min = 12, max = 36 }
-- under the portrait: a gap, the plaque (three rows), the area, a gap, the greeting and the date
M.PLAQUE_ROWS = 8
M.QUEST_CHANGE_ROWS = 3

local FRAMES = {
  normal   = { tl = "┌", tr = "┐", bl = "└", br = "┘", h = "─", v = "│", hl = "EldenHudFrame" },
  selected = { tl = "┏", tr = "┓", bl = "┗", br = "┛", h = "━", v = "┃", hl = "EldenHudFrameSel" },
}

-- sizes -----------------------------------------------------------------------------------

local function body_width(columns, chest_width) return columns * M.SLOT_WIDTH + M.PANE_GAP + chest_width end

-- rows the body takes besides the grid: title and tabs, the panes' titles, the description, the quest
local function fixed_rows(quest_rows) return 5 + 1 + 1 + 5 + 1 + 3 + quest_rows end

--- Decides how big everything is for a window: the portrait, the grid's columns and rows.
---@param model table needs width, height and portrait
---@return table plan { portrait?, columns, chest_width, grid_rows, quest_rows, body_width, stage_width, indent }
function M.plan(model)
  local inner = model.width - 2 * M.MARGIN
  local room = model.height - 2 - parts.FOOTER_ROWS
  -- the portrait comes first: it takes what is left after the smallest body that still reads well
  local portrait = model.portrait and hud.portrait_fit(inner - M.GAP - body_width(M.COLUMNS.min, M.CHEST_WIDTH.min),
    math.min(room - M.PLAQUE_ROWS, M.PORTRAIT.max), M.PORTRAIT.min) or nil
  local space = inner - (portrait and portrait.width + M.GAP or 0)
  local columns = hud.clamp(math.floor((space - M.PANE_GAP - M.CHEST_WIDTH.max) / M.SLOT_WIDTH), M.COLUMNS.min, M.COLUMNS.max)
  if space < body_width(columns, M.CHEST_WIDTH.min) then columns = 1 end
  local chest_width = hud.clamp(space - M.PANE_GAP - columns * M.SLOT_WIDTH, M.CHEST_WIDTH.min, M.CHEST_WIDTH.max)
  local quest_rows = room - fixed_rows(M.QUEST_CHANGE_ROWS) >= M.SLOT_HEIGHT and M.QUEST_CHANGE_ROWS or 0
  local grid_rows = hud.clamp(math.floor((room - fixed_rows(quest_rows)) / M.SLOT_HEIGHT), M.GRID_ROWS.min, M.GRID_ROWS.max)
  local stage_width = (portrait and portrait.width + M.GAP or 0) + body_width(columns, chest_width)
  return {
    portrait = portrait, columns = columns, chest_width = chest_width, grid_rows = grid_rows, quest_rows = quest_rows,
    body_width = body_width(columns, chest_width), stage_width = stage_width,
    indent = math.max(0, math.floor((model.width - stage_width) / 2)),
  }
end

-- the inventory ---------------------------------------------------------------------------

local function slot_line(frame, inner, text, hl, bg, spot)
  local left = math.floor((inner - vim.api.nvim_strwidth(text)) / 2)
  return {
    { frame.v, frame.hl }, { (" "):rep(left), bg = bg }, { text, hl, bg = bg, spot = spot },
    { (" "):rep(inner - left - vim.api.nvim_strwidth(text)), bg = bg }, { frame.v, frame.hl },
  }
end

local function slot(item, selected)
  local frame = selected and FRAMES.selected or FRAMES.normal
  local inner = M.SLOT_WIDTH - 2
  local bg = selected and "EldenHudSlotSel" or nil
  local key = item.key or ""
  local count = item.count and tostring(item.count) or ""
  local icon = hud.fit(vim.trim(item.icon or "·"), 2)
  local name = hud.fit(item.slot or item.name, inner - 2)
  return {
    { { frame.tl, frame.hl }, { key, "EldenHudKey" }, { frame.h:rep(inner - #key) .. frame.tr, frame.hl } },
    slot_line(frame, inner, icon, item.icon_hl or "EldenHudIcon", bg, selected and "cursor" or nil),
    slot_line(frame, inner, name, selected and "EldenHudName" or "EldenHudDesc", bg),
    { { frame.bl .. frame.h:rep(inner - 1 - #count), frame.hl }, { count, "EldenHudCount" }, { frame.h .. frame.br, frame.hl } },
  }
end

local function grid(items, cursor, focused, columns, offset, visible)
  local rows = {}
  local last_row = math.ceil(#items / columns) - 1
  for grid_row = offset, math.min(offset + visible - 1, last_row) do
    local band = { {}, {}, {}, {} }
    for col = 1, columns do
      local index = grid_row * columns + col
      if items[index] then
        for line, chunks in ipairs(slot(items[index], focused and index == cursor)) do
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
  local rows = { { { "Inventory", "EldenHudSection", spot = "fallback" } } }
  vim.list_extend(rows, grid(items, model.cursor.items, focused, plan.columns, offset, plan.grid_rows))
  if #items == 0 then table.insert(rows, { { "Nothing here yet", "EldenHudDim" } }) end
  return rows, { columns = plan.columns, count = #items, offset = offset, cursor_row = cursor_row }
end

-- the chest: Sites of Grace as a list, so every project keeps its full name and branch ------

-- the marker, key, icon and count take 14 cells, names share the rest with branches, one column for all
local function name_column(items, width)
  local longest = 0
  for _, item in ipairs(items) do longest = math.max(longest, vim.api.nvim_strwidth(item.name)) end
  return math.min(longest + 2, math.ceil((width - 14) * 0.55))
end

local function chest_row(item, selected, width, name_width)
  local bg = selected and "EldenHudSlotSel" or nil
  local count = item.count and ("● " .. item.count) or ""
  local rest = width - 14
  return {
    { selected and "▶ " or "  ", "EldenHudFrameSel", bg = bg },
    { hud.pad(item.key or "", 2), "EldenHudKey", bg = bg },
    { hud.pad(vim.trim(item.icon or ""), 2), item.icon_hl or "EldenHudIcon", bg = bg, spot = selected and "cursor" or nil },
    { " ", bg = bg },
    { hud.pad(item.name, name_width), selected and "EldenHudBanner" or "EldenHudName", bg = bg },
    { hud.pad(item.branch and (" " .. item.branch) or "", rest - name_width), "EldenHudDesc", bg = bg },
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
    table.insert(rows, chest_row(items[index], model.focus == "chest" and index == cursor, plan.chest_width, name_column(items, plan.chest_width)))
  end
  if #items == 0 then table.insert(rows, { { "No site found yet", "EldenHudDim" } }) end
  return rows, { columns = 1, count = #items, offset = offset, cursor_row = cursor - 1 }
end

-- the rest of the body ----------------------------------------------------------------------

local function tab_bar(model)
  local bar, rule = { { "◁ ", "EldenHudDim" } }, { { "  " } }
  for index, tab in ipairs(model.tabs) do
    local active = index == model.tab
    table.insert(bar, { hud.pad("  " .. vim.trim(tab.icon), M.TAB_WIDTH), active and "EldenHudTabSel" or "EldenHudTab" })
    table.insert(rule, { (active and "━" or "─"):rep(M.TAB_WIDTH), active and "EldenHudRuleSel" or "EldenHudRule" })
  end
  table.insert(bar, { " ▷   ", "EldenHudDim" })
  table.insert(bar, { model.tabs[model.tab].title, "EldenHudTitle" })
  return bar, rule
end

local HINTS = "⏎ Use   K Check   C Combine   ⇥ Tabs   hjkl Move   j Quest   s Session   q Quit"

local function description(item, width)
  local rows = { { { ("─"):rep(width), "EldenHudRule" } } }
  local lines = item and hud.wrap(item.desc or "", width - 2) or {}
  table.insert(rows, { { " " .. (item and hud.fit(item.name, width - 2) or ""), "EldenHudName" } })
  for index = 1, 2 do table.insert(rows, { { " " .. (lines[index] or ""), "EldenHudDesc" } }) end
  table.insert(rows, { { " " .. hud.fit(HINTS, width - 2), "EldenHudHint" } })
  return rows
end

local function rule(label, width)
  local head = "◈── " .. label .. " "
  return { { head .. ("─"):rep(math.max(2, width - vim.api.nvim_strwidth(head) - 1)) .. "◈", "EldenHudSection" } }
end

local function quest(model, plan)
  local status = model.status or {}
  local width = plan.body_width
  local last_selected, change = parts.quest_selection(model)
  local title = rule(model.focus == "quest" and "Current Quest ▼" or "Current Quest  j", width)
  if model.focus == "quest" then title[1][2] = "EldenHudTitle" end
  local rows = {
    title,
    hud.indent({ parts.quest_line(status, width - 2, "No quest here, p travels to one of your " .. (model.sites or "projects")) }, 1)[1],
  }
  if status.last_file then
    local bg = last_selected and "EldenHudSlotSel" or nil
    table.insert(rows, {
      { last_selected and "▶ " or "  ", "EldenHudFrameSel" }, { "↳ last  ", "EldenHudDim", bg = bg, spot = last_selected and "cursor" or nil },
      { hud.fit(status.last_file, width - 12), last_selected and "EldenHudBanner" or "EldenHudName", bg = bg },
    })
  else
    table.insert(rows, {})
  end
  vim.list_extend(rows, hud.indent(parts.changes(status.changes or {}, width - 4, plan.quest_rows, change), 2))
  -- a fixed height, so the stage never shifts when the changes arrive from git
  while #rows < 3 + plan.quest_rows do table.insert(rows, {}) end
  return rows
end

local function panes(model, plan)
  local inventory_rows, inventory_grid = inventory(model, plan)
  local chest_rows, chest_grid = chest(model, plan)
  local height = 1 + plan.grid_rows * M.SLOT_HEIGHT
  local rows = hud.beside(inventory_rows, plan.columns * M.SLOT_WIDTH, chest_rows, M.PANE_GAP)
  while #rows < height do table.insert(rows, {}) end
  return rows, { items = inventory_grid, chest = chest_grid }
end

local function body(model, plan)
  local width = plan.body_width
  local hub = require("core.banner.actions").spaced(model.hub or "")
  local bar, tab_rule = tab_bar(model)
  local rows = { hud.center({ { "◈   " .. hub .. "   ◈", "EldenHudTitle" } }, width), {}, bar, tab_rule, {} }
  local pane_rows, grids = panes(model, plan)
  vim.list_extend(rows, pane_rows)
  table.insert(rows, {})
  vim.list_extend(rows, description(parts.selected(model), width))
  table.insert(rows, {})
  vim.list_extend(rows, quest(model, plan))
  return rows, grids
end

-- the champion ------------------------------------------------------------------------------

local function champion(model, portrait)
  local width = portrait.width
  local rows = { { { "", spot = "portrait" } } }
  for _ = 2, portrait.height do table.insert(rows, {}) end
  local ornament = "◈" .. ("━"):rep(width - 2) .. "◈"
  vim.list_extend(rows, {
    {},
    { { ornament, "EldenHudTitle" } },
    hud.center({ { parts.champion_name(model.character or "", width), "EldenHudTitle" } }, width),
    { { ornament, "EldenHudTitle" } },
    hud.center({ { hud.fit(model.area or "", width), "EldenHudSection" } }, width),
    {},
    hud.center({ { hud.fit(model.greeting or "", width), "EldenHudName" } }, width),
    hud.center({ { hud.fit(model.date or "", width), "EldenHudDim" } }, width),
  })
  return rows
end

--- Lays out the whole Elden Ring hub for a model.
---@param model table HUD state: tabs, tab, focus, cursor, offset, chest, status, message, width, height
---@return table view { lines, marks, cursor, grids, anchors, plan }
function M.render(model)
  local plan = M.plan(model)
  local rows, grids = body(model, plan)
  grids.quest = { columns = 1, count = parts.quest_count(model.status or {}, plan.quest_rows), offset = 0, cursor_row = (model.cursor.quest or 1) - 1 }
  if plan.portrait then
    local column = champion(model, plan.portrait)
    local height = math.max(#column, #rows)
    rows = hud.beside(hud.middle(column, height), plan.portrait.width, hud.middle(rows, height), M.GAP)
  end
  vim.list_extend(rows, parts.footer(model, plan.stage_width))
  local lines, marks, spots = hud.compose(hud.indent(rows, plan.indent))
  local cursor = spots.cursor or spots.fallback
  local anchors = {}
  if plan.portrait and spots.portrait then
    anchors.portrait = vim.tbl_extend("force", spots.portrait, plan.portrait)
  end
  return {
    lines = lines, marks = marks, grids = grids, anchors = anchors, plan = plan,
    cursor = { row = cursor.row + 1, col = cursor.col },
  }
end

return M
