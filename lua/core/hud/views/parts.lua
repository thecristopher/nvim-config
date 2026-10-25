-- Pieces both HUD views share: the champion's name on a plaque, the changed files of the quest and
-- the footer with the message and the stats. Pure: they only turn data into rows of chunks.
local hud = require("core.hud.actions")

local M = {}

--- Letterspaces the champion's name as wide as the room allows: carved, then banner style, then plain.
---@param character string
---@param width integer
---@return string
function M.champion_name(character, width)
  local carved = require("core.hub.actions").spaced(character)
  if vim.api.nvim_strwidth(carved) <= width then return carved end
  local spaced = require("core.banner.actions").spaced(character)
  if vim.api.nvim_strwidth(spaced) <= width then return spaced end
  return hud.fit(character:upper(), width)
end

local STATUS_HL = { M = "EldenHudKey", A = "EldenHudTitle", D = "EldenHudDim", R = "EldenHudKey", ["?"] = "EldenHudCount" }

local function change_chunks(line, width, selected)
  local code = vim.trim(line:sub(1, 2))
  local path = line:sub(4)
  local bg = selected and "EldenHudSlotSel" or nil
  return {
    { hud.pad(code, 3), STATUS_HL[code:sub(1, 1)] or "EldenHudCount", bg = bg, spot = selected and "cursor" or nil },
    { hud.pad(hud.fit(path, width - 4), width - 3), selected and "EldenHudBanner" or "EldenHudDesc", bg = bg },
  }
end

--- Lays changed files (porcelain lines) in two columns, as many rows as given. When they do not
--- all fit, the last cell says how many more there are, and while one is selected the page that
--- holds it is shown instead.
---@param changes string[]
---@param width integer
---@param rows integer
---@param selected? integer the selected change, when the quest has the focus
---@return table[] rows of chunks
function M.changes(changes, width, rows, selected)
  local column = math.floor((width - 2) / 2)
  local capacity = rows * 2
  if capacity == 0 then return {} end
  local first = selected and math.floor((selected - 1) / capacity) * capacity or 0
  local shown = math.min(#changes - first, capacity)
  if not selected and #changes > capacity then shown = capacity - 1 end
  local cells = {}
  for cell = 1, shown do
    local index = first + cell
    cells[cell] = change_chunks(changes[index], column, index == selected)
  end
  if not selected and shown < #changes then cells[capacity] = { { ("+%d more"):format(#changes - shown), "EldenHudDim" } } end
  local out = {}
  for row = 1, rows do
    local left, right = cells[row], cells[row + rows]
    if not left then break end
    local chunks = hud.pad_chunks(left, column)
    if right then
      table.insert(chunks, { "  " })
      vim.list_extend(chunks, right)
    end
    table.insert(out, chunks)
  end
  return out
end

--- The item under the cursor in whichever pane has the focus.
---@param model table
---@return table|nil
function M.selected(model)
  if model.selected then return model.selected end
  if model.focus == "chest" and model.chest then return model.chest.items[model.cursor.chest or 1] end
  return model.tabs[model.tab].items[model.cursor.items or 1]
end

--- Tells which quest entry is selected: the last file or one of the changes.
---@param model table
---@return boolean last_selected, integer|nil change index
function M.quest_selection(model)
  if model.focus ~= "quest" then return false, nil end
  local index = model.cursor.quest or 1
  local status = model.status or {}
  if status.last_ready then
    if index == 1 then return true, nil end
    return false, index - 1
  end
  return false, index
end

--- How many quest entries the cursor can reach: the last file and the changes that have room.
---@param status table
---@param change_rows integer
---@return integer
function M.quest_count(status, change_rows)
  local changes = change_rows > 0 and #(status.changes or {}) or 0
  return (status.last_ready and 1 or 0) + changes
end

--- The line naming the quest: project, branch and how much changed.
---@param status table
---@param width integer
---@param fallback string what to say outside a repo
---@return table[] chunks
function M.quest_line(status, width, fallback)
  if not status.project then return { { hud.fit(fallback, width), "EldenHudDim" } } end
  local count = status.changes and #status.changes or nil
  local tally = count == nil and "counting…" or count == 0 and "clean" or (count .. " changed")
  -- the icons, the gaps and the dot take 14 cells, the branch gets what the name and tally leave
  local branch_width = math.max(4, width - 14 - vim.api.nvim_strwidth(status.project) - vim.api.nvim_strwidth(tally))
  return hud.clip({
    { "󰊢 ", "EldenHudIcon" }, { status.project, "EldenHudBanner" }, { "    ", nil },
    { " ", "EldenHudKey" }, { hud.fit(status.branch or "?", branch_width), "EldenHudName" }, { "    " },
    { "● ", count and count > 0 and "EldenHudKey" or "EldenHudDim" }, { tally, "EldenHudCount" },
  }, width)
end

--- The footer under the whole stage: the player message and the stats, both centered.
---@param model table
---@param width integer
---@return table[] rows
function M.footer(model, width)
  local rows = { {} }
  local message = model.message or ""
  -- the hub's quill finds the message by its exact text, so it is only cut when it truly cannot fit
  table.insert(rows, hud.center({ { hud.fit(message, width), "SnacksDashboardDesc" } }, width))
  if model.stats then table.insert(rows, hud.center({ { hud.fit(model.stats, width), "EldenHudDim" } }, width)) end
  return rows
end

M.FOOTER_ROWS = 3

return M
