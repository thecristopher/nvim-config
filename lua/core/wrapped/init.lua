-- :Wrapped [year] or <leader>jw: the year told in one card from the chronicle, the bestiary and the
-- feats, in the world's words. s saves it as a PNG through core/snapshot, ready to share.
local actions = require("core.wrapped.actions")

local M = {}

local ns = vim.api.nvim_create_namespace("eldentree_wrapped")

local function read_state(name)
  local ok, lines = pcall(vim.fn.readfile, vim.fn.stdpath("state") .. "/" .. name)
  if not ok then
    return {}
  end
  local decoded_ok, decoded = pcall(vim.json.decode, table.concat(lines, "\n"))
  return (decoded_ok and type(decoded) == "table") and decoded or {}
end

-- the foe and the feats named the way the world of the day names them, and the song of the year
local function named(summary, lore)
  local foe = summary.foe
    and require("core.bestiary.actions").enemy(summary.foe, lore.bestiary.enemies)
  local feats = vim.tbl_map(function(id)
    return lore.trophies.feats[id] or id
  end, summary.feats)
  local song = require("core.music.actions.history").top(
    read_state("eldentree_music.json"),
    tostring(summary.year)
  )
  return { foe = foe, feats = feats, song = song }
end

local function card_lines(rows)
  local width = 0
  for _, row in ipairs(rows) do
    width = math.max(width, vim.api.nvim_strwidth(row.label or ""))
  end
  local lines = {}
  for index, row in ipairs(rows) do
    local label = row.label
        and (row.label .. (" "):rep(width - vim.api.nvim_strwidth(row.label)) .. "  ")
      or ""
    lines[index] = { label = label, value = row.value }
  end
  return lines
end

-- the same lines as runs with colors, for the PNG
local function styled(lines)
  local p = require("core.themes").palette()
  return vim.tbl_map(function(line)
    local runs = {}
    if line.label ~= "" then
      table.insert(runs, { text = line.label, fg = p.overlay1 })
    end
    table.insert(
      runs,
      { text = line.value, fg = line.label ~= "" and p.text or p.yellow, bold = true }
    )
    return runs
  end, lines)
end

local function paint(buf, lines)
  local text = vim.tbl_map(function(line)
    return " " .. line.label .. line.value .. " "
  end, lines)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, text)
  for index, line in ipairs(lines) do
    local label_end = 1 + #line.label
    if line.label ~= "" then
      vim.api.nvim_buf_set_extmark(
        buf,
        ns,
        index - 1,
        1,
        { end_col = label_end, hl_group = "Comment" }
      )
    end
    -- the values keep the float's own colors, only the heading lines wear the accent
    if line.label == "" then
      vim.api.nvim_buf_set_extmark(
        buf,
        ns,
        index - 1,
        label_end,
        { end_col = #text[index], hl_group = "EldenFeatHeader" }
      )
    end
  end
  vim.bo[buf].modifiable = false
  return text
end

local function open_card(title, lines)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  local text = paint(buf, lines)
  local width = vim.api.nvim_strwidth(title) + 6
  for _, line in ipairs(text) do
    width = math.max(width, vim.api.nvim_strwidth(line))
  end
  width = math.min(width, vim.o.columns - 4)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    style = "minimal",
    border = require("core.skin").border(),
    width = width,
    height = math.min(#text, vim.o.lines - 6),
    row = 2,
    col = math.floor((vim.o.columns - width) / 2),
    title = " " .. require("core.skin").title(title) .. " ",
    title_pos = "center",
    footer = " s save as PNG · q close ",
    footer_pos = "center",
  })
  return buf, win
end

--- Opens the card of a year, this one by default.
---@param year integer|nil
function M.open(year)
  year = year or tonumber(os.date("%Y")) or 0
  local lore = require("core.franchise").current()
  local summary = actions.summary({
    chronicle = read_state("eldentree_chronicle.json"),
    bestiary = read_state("eldentree_bestiary.json"),
    feats = require("core.feats").store(),
  }, year)
  local title = lore.chronicle.year:format(year)
  if actions.empty(summary) then
    return vim.notify(
      "Nothing fought in " .. year .. " yet",
      vim.log.levels.INFO,
      { title = title }
    )
  end
  local lines = card_lines(actions.rows(summary, named(summary, lore)))
  require("core.sound").play("files")
  local buf, win = open_card(title, lines)
  vim.keymap.set("n", "s", function()
    require("core.snapshot").card(styled(lines), { title = title, name = "wrapped-" .. year })
  end, { buffer = buf, nowait = true, desc = "Save the year card as a PNG" })
  for _, key in ipairs({ "q", "<Esc>" }) do
    vim.keymap.set("n", key, function()
      pcall(vim.api.nvim_win_close, win, true)
    end, { buffer = buf, nowait = true })
  end
end

local recap_file = vim.fn.stdpath("state") .. "/eldentree_recap"
-- after the title screen and the season, so the three never share the screen
local RECAP_AFTER_MS = 12000

--- Tells how last week went, once, on the first start of a new week.
---@param force boolean|nil true shows it again even if this week already had it
function M.recap(force)
  local today = tostring(os.date("%Y-%m-%d"))
  local this_week = actions.monday_of(today)
  local ok, seen = pcall(vim.fn.readfile, recap_file, "", 1)
  if not force and ok and seen[1] == this_week then
    return
  end
  local lore = require("core.franchise").current()
  local week = actions.last_week({
    chronicle = read_state("eldentree_chronicle.json"),
    feats = require("core.feats").store(),
  }, today)
  require("core.utils").write_state(recap_file, { this_week })
  if week.days == 0 then
    return
  end
  local names = vim.tbl_map(function(id)
    return lore.trophies.feats[id] or id
  end, week.feats)
  local title = ("%s · %s to %s"):format(lore.chronicle.title, week.from:sub(6), week.to:sub(6))
  vim.notify(
    table.concat(actions.week_lines(week, names), "\n"),
    vim.log.levels.INFO,
    { title = title }
  )
end

function M.setup()
  vim.defer_fn(M.recap, RECAP_AFTER_MS)
  vim.api.nvim_create_user_command("Wrapped", function(cmd)
    if cmd.args == "week" then
      return M.recap(true)
    end
    M.open(tonumber(cmd.args))
  end, {
    nargs = "?",
    complete = function()
      return { "week" }
    end,
    desc = "The year told in one card (s saves it as a PNG), or :Wrapped week for last week",
  })
end

return M
