-- Feats: trophies you unlock once and keep, judged on every save from what the bestiary, the
-- chronicle and the run already count. Each unlock pops a toast, :Feats or <leader>ja shows the
-- showcase, and the cycle (new game plus) rises with every full year since your first day.
local actions = require("core.feats.actions")
local toast = require("core.feats.toast")

local M = {}

local store_file = vim.fn.stdpath("state") .. "/eldentree_feats.json"
local ns = vim.api.nvim_create_namespace("eldentree_feats")
-- the check waits for a quiet moment after a save, so a burst of saves reads the stores once
local CHECK_AFTER_MS = 1500
local STARTUP_CHECK_MS = 4000

local night = false
local pending

local function read_json(path)
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok then
    return {}
  end
  local decoded_ok, decoded = pcall(vim.json.decode, table.concat(lines, "\n"))
  return (decoded_ok and type(decoded) == "table") and decoded or {}
end

local function state(name)
  return read_json(vim.fn.stdpath("state") .. "/" .. name)
end

--- The feats unlocked so far, { [id] = date }.
---@return table
function M.store()
  return read_json(store_file)
end

---@return string
local function today()
  return tostring(os.date("%Y-%m-%d"))
end

--- The cycle you are on, 1 until a year after the chronicle's first day.
---@return integer
function M.cycle()
  return actions.cycle(state("eldentree_chronicle.json"), today())
end

--- How the world names the cycle you are on, nil on the first one.
---@return string|nil
function M.cycle_label()
  return actions.cycle_label(M.cycle(), require("core.franchise").current().trophies.cycle)
end

--- Unlocks every feat earned so far and announces the new ones.
function M.check()
  local run = require("core.results").current()
  run.night = night
  local chronicle = state("eldentree_chronicle.json")
  local stats = actions.stats(state("eldentree_bestiary.json"), chronicle, run, today())
  local store = M.store()
  local fresh = actions.newly(store, stats)
  if #fresh == 0 then
    return
  end
  require("core.utils").write_state(
    store_file,
    { vim.json.encode(actions.record(store, fresh, today())) }
  )
  local said = require("core.franchise").current().trophies
  for _, feat in ipairs(fresh) do
    toast.push({ header = said.unlocked, name = said.feats[feat.id] or feat.id, desc = feat.desc })
  end
end

local function check_soon()
  if pending then
    pending:stop()
  end
  pending = vim.defer_fn(function()
    pending = nil
    M.check()
  end, CHECK_AFTER_MS)
end

local function render(entries)
  local skin = require("core.skin").current().tree
  local width = 0
  for _, entry in ipairs(entries) do
    width = math.max(width, vim.api.nvim_strwidth(entry.name))
  end
  local lines, marks = {}, {}
  for index, entry in ipairs(entries) do
    local mark = entry.date and skin.cleared or skin.left
    local name = entry.name .. (" "):rep(width - vim.api.nvim_strwidth(entry.name))
    local when = entry.date or "locked"
    lines[index] = (" %s  %s  %-10s  %s "):format(mark, name, when, entry.desc)
    local name_start = 1 + #mark + 2
    local group = entry.date and "EldenMapCleared" or "Comment"
    marks[index] =
      { { 0, name_start + #name, group }, { name_start + #name, #lines[index], "Comment" } }
  end
  return lines, marks
end

--- Opens the showcase: every feat, unlocked with its day or still locked.
function M.open()
  local said = require("core.franchise").current().trophies
  local store = M.store()
  local lines, marks = render(actions.entries(store, said.feats))
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  for row, line_marks in ipairs(marks) do
    for _, mark in ipairs(line_marks) do
      vim.api.nvim_buf_set_extmark(
        buf,
        ns,
        row - 1,
        mark[1],
        { end_col = mark[2], hl_group = mark[3] }
      )
    end
  end
  vim.bo[buf].modifiable = false
  local width = 0
  for _, line in ipairs(lines) do
    width = math.max(width, vim.api.nvim_strwidth(line))
  end
  width = math.min(width, vim.o.columns - 4)
  local unlocked, total = actions.count(store)
  local cycle = M.cycle_label()
  local footer = (" %d of %d unlocked%s "):format(
    unlocked,
    total,
    cycle and (" · " .. cycle) or ""
  )
  require("core.sound").play("files")
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    style = "minimal",
    border = require("core.skin").border(),
    width = width,
    height = math.min(#lines, vim.o.lines - 6),
    row = 2,
    col = math.floor((vim.o.columns - width) / 2),
    title = " " .. require("core.skin").title(said.title) .. " ",
    title_pos = "center",
    footer = footer,
    footer_pos = "center",
  })
  vim.wo[win].cursorline = true
  for _, key in ipairs({ "q", "<Esc>" }) do
    vim.keymap.set("n", key, function()
      pcall(vim.api.nvim_win_close, win, true)
    end, { buffer = buf, nowait = true })
  end
end

--- Pops the toast of the first feat, unlocked or not, to see how the world announces one.
function M.preview()
  local said = require("core.franchise").current().trophies
  local feat = actions.FEATS[1]
  toast.push({ header = said.unlocked, name = said.feats[feat.id] or feat.id, desc = feat.desc })
end

function M.setup()
  toast.define_highlights()
  local group = vim.api.nvim_create_augroup("eldentree_feats", { clear = true })
  vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = toast.define_highlights })
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    callback = function()
      night = night or actions.night(tonumber(os.date("%H")) or 0)
      check_soon()
    end,
  })
  -- yesterday's run lands in the chronicle on exit, so its rank is judged on the next start
  vim.defer_fn(M.check, STARTUP_CHECK_MS)
  vim.api.nvim_create_user_command("Feats", function(cmd)
    if cmd.args == "preview" then
      return M.preview()
    end
    M.open()
  end, {
    nargs = "?",
    complete = function()
      return { "preview" }
    end,
    desc = "Every feat, unlocked or locked, or :Feats preview to see a toast",
  })
end

return M
