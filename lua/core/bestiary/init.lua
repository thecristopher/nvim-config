-- The bestiary of a repo: every error or warning you clear by editing counts as a foe felled,
-- named from the franchise's enemies. :Bestiary or <leader>ub shows which ones you fight the most.
local actions = require("core.bestiary.actions")

local M = {}

local store_file = vim.fn.stdpath("state") .. "/eldentree_bestiary.json"
-- the last reading per buffer, with the changedtick it was taken at
local readings = {}

local function read_store()
  local ok, lines = pcall(vim.fn.readfile, store_file)
  if not ok then
    return {}
  end
  local decoded_ok, decoded = pcall(vim.json.decode, table.concat(lines, "\n"))
  return (decoded_ok and type(decoded) == "table") and decoded or {}
end

local function write_store(store)
  pcall(vim.fn.writefile, { vim.json.encode(store) }, store_file)
end

local function repo_of(buf)
  local root = vim.fs.root(buf, ".git")
  return root and vim.fs.normalize(root) or nil
end

local SEVERITIES = { min = vim.diagnostic.severity.WARN }

-- only a reading taken after an edit can fell anything, closing a buffer clears its diagnostics too
local function read(buf)
  if not vim.api.nvim_buf_is_loaded(buf) or vim.bo[buf].buftype ~= "" then
    return
  end
  local tick = vim.api.nvim_buf_get_changedtick(buf)
  local counts = actions.tally(vim.diagnostic.get(buf, { severity = SEVERITIES }))
  local before = readings[buf]
  readings[buf] = { counts = counts, tick = tick }
  if not before or before.tick == tick then
    return
  end
  local kills = actions.felled(before.counts, counts)
  local repo = repo_of(buf)
  if not repo or next(kills) == nil then
    return
  end
  write_store(actions.record(read_store(), repo, kills, os.date("%Y-%m-%d")))
end

local function render(entries)
  local width = 0
  for _, entry in ipairs(entries) do
    width = math.max(width, vim.api.nvim_strwidth(entry.enemy))
  end
  local lines, marks = {}, {}
  for index, entry in ipairs(entries) do
    local name = entry.enemy .. (" "):rep(width - vim.api.nvim_strwidth(entry.enemy))
    local count = ("×%-4d"):format(entry.kills)
    lines[index] = (" %s  %s  %s"):format(name, count, entry.key)
    local name_end = 1 + #name
    marks[index] = {
      { 1, name_end, "EldenMapCleared" },
      { name_end + 2, name_end + 2 + #count, "DiagnosticWarn" },
      { name_end + 4 + #count, #lines[index], "EldenMapPath" },
    }
  end
  return lines, marks
end

local ns = vim.api.nvim_create_namespace("eldentree_bestiary")

--- Opens the bestiary of the repo you stand in.
function M.open()
  local lore = require("core.franchise").current().bestiary
  local repo = repo_of(0) or vim.fs.normalize(require("core.repos").root() or vim.uv.cwd())
  local entries = actions.entries(read_store(), repo, lore.enemies)
  if #entries == 0 then
    return vim.notify(lore.empty, vim.log.levels.INFO, { title = lore.title })
  end
  local lines, marks = render(entries)
  local width = 30
  for _, line in ipairs(lines) do
    width = math.max(width, vim.api.nvim_strwidth(line) + 2)
  end
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
  local felled = 0
  for _, entry in ipairs(entries) do
    felled = felled + entry.kills
  end
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    style = "minimal",
    border = require("core.skin").border(),
    width = math.min(width, vim.o.columns - 4),
    height = math.min(#lines, vim.o.lines - 6),
    row = 2,
    col = math.floor((vim.o.columns - width) / 2),
    title = " " .. require("core.skin").title(lore.title) .. " ",
    title_pos = "center",
    footer = (" %d kinds · %d felled "):format(#entries, felled),
    footer_pos = "center",
  })
  vim.wo[win].cursorline = true
  for _, key in ipairs({ "q", "<Esc>" }) do
    vim.keymap.set("n", key, function()
      pcall(vim.api.nvim_win_close, win, true)
    end, { buffer = buf, nowait = true })
  end
end

function M.setup()
  local group = vim.api.nvim_create_augroup("eldentree_bestiary", { clear = true })
  vim.api.nvim_create_autocmd("DiagnosticChanged", {
    group = group,
    callback = function(ev)
      read(ev.buf)
    end,
  })
  vim.api.nvim_create_autocmd("BufWipeout", {
    group = group,
    callback = function(ev)
      readings[ev.buf] = nil
    end,
  })
  vim.api.nvim_create_user_command("Bestiary", M.open, { desc = "The foes felled in this repo" })
  vim.keymap.set("n", "<leader>ub", M.open, { desc = "Bestiary" })
end

return M
