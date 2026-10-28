-- The Resident Evil hub: the STATUS panel with the survivor's portrait standing tall over their name
-- and area, the item grid under plate tabs with the COMMAND menu, the DATA of the
-- quest you left open, and the selected item's name across the bottom like the old item banners.
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
M.PORTRAIT = { min = 8, max = 32 }
-- the STATUS frame around the portrait: borders, gaps, the name and the area
M.STATUS_ROWS = 7
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

-- rows the right column takes besides the grid: plates, gaps and the DATA box
local function fixed_rows(change_rows)
  return 2 + 1 + 2 + M.DATA_ROWS + change_rows
end

--- Decides how big everything is for a window: the portrait, the STATUS panel and the grid.
---@param model table needs width, height and portrait
---@return table plan { portrait?, status_width, columns, grid_rows, change_rows, items_width, stacked, stage_width, indent }
function M.plan(model)
  local inner = model.width - 2 * M.MARGIN
  local stacked = model.width - 2 * M.MARGIN < M.STATUS_MIN + M.GAP + items_width(M.COLUMNS.min)
  local room = model.height - 2 - M.FOOTER_ROWS - (stacked and 2 or 0)
  local change_rows = room - fixed_rows(M.CHANGE_ROWS) >= M.SLOT_HEIGHT and M.CHANGE_ROWS or 0
  local grid_rows = hud.clamp(
    math.floor((room - fixed_rows(change_rows)) / M.SLOT_HEIGHT),
    M.GRID_ROWS.min,
    M.GRID_ROWS.max
  )
  local portrait = not stacked
      and model.portrait
      and hud.portrait_fit(
        inner - M.GAP - items_width(M.COLUMNS.min) - 6,
        math.min(room - M.STATUS_ROWS, M.PORTRAIT.max),
        M.PORTRAIT.min
      )
    or nil
  local status_width = math.max(M.STATUS_MIN, portrait and portrait.width + 6 or 0)
  local beside = stacked and 0 or status_width + M.GAP
  local columns =
    hud.clamp(math.floor((inner - beside - 1 - M.MENU_WIDTH) / M.SLOT_WIDTH), 1, M.COLUMNS.max)
  if stacked then
    status_width = items_width(columns)
  end
  local stage_width = beside + items_width(columns)
  return {
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
  return { hud.center(hud.clip(name, plan.status_width), plan.status_width), {} }
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
  table.insert(
    body,
    hud.center({ { hud.fit(status.area or "", inner - 2), "EldenHudSection" } }, inner)
  )
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

local function slot(item, selected)
  local frame = selected and FRAMES.selected or FRAMES.normal
  local inner = M.SLOT_WIDTH - 2
  local bg = selected and "EldenHudSlotSel" or nil
  local icon = hud.pad(vim.trim(item.icon or "·"), 2)
  local key = item.key and ("[" .. item.key .. "]") or ""
  local count = item.count and tostring(item.count) or ""
  return {
    { { frame.tl .. frame.h:rep(inner) .. frame.tr, frame.hl } },
    {
      { frame.v, frame.hl },
      { " ", bg = bg },
      { icon, item.icon_hl or "EldenHudIcon", bg = bg, spot = selected and "cursor" or nil },
      {
        hud.pad(item.slot or item.name, inner - 3),
        selected and "EldenHudName" or "EldenHudDesc",
        bg = bg,
      },
      { frame.v, frame.hl },
    },
    {
      { frame.v, frame.hl },
      { " ", bg = bg },
      { key, "EldenHudKey", bg = bg },
      { (" "):rep(inner - 2 - #key - #count), bg = bg },
      { count, "EldenHudCount", bg = bg },
      { " ", bg = bg },
      { frame.v, frame.hl },
    },
    { { frame.bl .. frame.h:rep(inner) .. frame.br, frame.hl } },
  }
end

local function grid(items, cursor, columns, offset, visible)
  local rows = {}
  local last_row = math.ceil(#items / columns) - 1
  for grid_row = offset, math.min(offset + visible - 1, last_row) do
    local band = { {}, {}, {}, {} }
    for col = 1, columns do
      local index = grid_row * columns + col
      if items[index] then
        for line, chunks in ipairs(slot(items[index], index == cursor)) do
          vim.list_extend(band[line], chunks)
        end
      end
    end
    vim.list_extend(rows, band)
  end
  return rows
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
  local function field(label, text, hl)
    return {
      { " " .. hud.pad(label, 7), "EldenHudDim" },
      { hud.fit(text or "·", value), hl or "EldenHudName" },
    }
  end
  local last = field("LAST", status.last_file)
  if last_selected then
    last = {
      { " " .. hud.pad("▶ LAST", 7), "EldenHudFrameSel" },
      {
        hud.fit(status.last_file, value),
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

local function items_column(model, plan)
  local items = model.tabs[model.tab].items
  local cursor = model.cursor.items or 1
  local cursor_row = math.floor((cursor - 1) / plan.columns)
  local offset = hud.scroll(cursor_row, plan.grid_rows, model.offset.items or 0)
  local slots = grid(items, cursor, plan.columns, offset, plan.grid_rows)
  if #items == 0 then
    slots = { {}, { { "  Nothing here yet", "EldenHudDim" } } }
  end
  local rows = { tab_plates(model), {} }
  local grid_area = hud.beside(slots, plan.columns * M.SLOT_WIDTH, command_menu(model.menu), 1)
  -- the grid keeps its height whatever the tab holds, so nothing below it moves
  while #grid_area < plan.grid_rows * M.SLOT_HEIGHT do
    table.insert(grid_area, {})
  end
  vim.list_extend(rows, grid_area)
  table.insert(rows, {})
  vim.list_extend(rows, data_box(model, plan))
  return rows, { columns = plan.columns, count = #items, offset = offset, cursor_row = cursor_row }
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

local function banner(item, width)
  -- spaced first and cut after, the spacing works on bytes and would split a cut ellipsis
  local name = item and hud.fit(require("core.banner.actions").spaced(item.name), width - 8) or ""
  local side = math.max(2, math.floor((width - vim.api.nvim_strwidth(name) - 4) / 2))
  local rows = {
    {
      { ("═"):rep(side) .. "╡ ", "EldenHudFrame" },
      { name, "EldenHudBanner" },
      { " ╞" .. ("═"):rep(width - side - vim.api.nvim_strwidth(name) - 4), "EldenHudFrame" },
    },
  }
  local lines = item and hud.wrap(item.desc or "", width - 2) or {}
  for index = 1, 2 do
    table.insert(rows, hud.center({ { lines[index] or "", "EldenHudDesc" } }, width))
  end
  return rows
end

local HINTS = "⏎ Command   K Check   ⇥ Tabs   hjkl Move   j DATA   s Session   q Quit"

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
    local height = math.max(#status, #items)
    rows =
      hud.beside(hud.middle(status, height), plan.status_width, hud.middle(items, height), M.GAP)
  end
  table.insert(rows, {})
  vim.list_extend(rows, banner(parts.selected(model), plan.stage_width))
  table.insert(rows, hud.center({ { HINTS, "EldenHudHint" } }, plan.stage_width))
  table.insert(rows, {})
  table.insert(
    rows,
    hud.center(
      { { hud.fit(model.message or "", plan.stage_width), "SnacksDashboardDesc" } },
      plan.stage_width
    )
  )
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
