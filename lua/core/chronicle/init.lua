-- :Chronicle or <leader>uj: the weeks you fought as a grid, each day lit by its rank and by the
-- commits you made in the repo you stand in. Every run that ends adds to its day.
local actions = require("core.chronicle.actions")
local color = require("core.motion.actions")

local M = {}

local history_file = vim.fn.stdpath("state") .. "/eldentree_chronicle.json"
local ns = vim.api.nvim_create_namespace("eldentree_chronicle")

local function read_history()
  local ok, lines = pcall(vim.fn.readfile, history_file)
  if not ok then
    return {}
  end
  local decoded_ok, decoded = pcall(vim.json.decode, table.concat(lines, "\n"))
  return (decoded_ok and type(decoded) == "table") and decoded or {}
end

--- Adds a finished run to today's entry of the chronicle.
---@param run { seconds: integer, saves: integer, fixes: integer }
function M.record(run)
  local history = actions.merge_day(read_history(), os.date("%Y-%m-%d"), run)
  pcall(vim.fn.writefile, { vim.json.encode(history) }, history_file)
end

local function define_highlights()
  local p = require("core.themes").palette()
  local dim, bright = color.to_int(p.surface1), color.to_int(p.yellow)
  for level = 0, actions.LEVELS do
    local glow = color.mix(dim, bright, level / actions.LEVELS)
    vim.api.nvim_set_hl(0, "EldenChronicle" .. level, { fg = glow })
  end
end

local function commits(root, since)
  if not root then
    return {}
  end
  local email = vim.trim(vim.fn.system({ "git", "-C", root, "config", "user.email" }))
  local args = { "git", "-C", root, "log", "--since=" .. since, "--format=%ad", "--date=short" }
  if email ~= "" then
    table.insert(args, "--author=" .. email)
  end
  local result = vim.system(args, { text = true }):wait(5000)
  return result.code == 0 and actions.commits_per_day(result.stdout) or {}
end

local function render(rows)
  local lines, marks = {}, {}
  for index, row in ipairs(rows) do
    local line = " " .. actions.DAYS[index] .. " "
    marks[index] = {}
    for _, cell in ipairs(row) do
      local glyph = cell.future and " " or "■"
      table.insert(marks[index], { #line, #line + #glyph, "EldenChronicle" .. cell.level })
      line = line .. glyph .. " "
    end
    lines[index] = line
  end
  return lines, marks
end

local function footer(totals)
  local parts = { ("%d days fought"):format(totals.days) }
  for _, rank in ipairs({ "S", "A", "B", "C", "D" }) do
    if totals.ranks[rank] then
      table.insert(parts, ("%s×%d"):format(rank, totals.ranks[rank]))
    end
  end
  return " " .. table.concat(parts, " · ") .. " "
end

--- Opens the chronicle of the last weeks.
function M.open()
  local history = read_history()
  local since = os.date("%Y-%m-%d", os.time() - actions.WEEKS * 7 * 86400)
  local rows =
    actions.grid(history, commits(require("core.repos").root(), since), os.date("%Y-%m-%d"))
  local lines, marks = render(rows)
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
  local title = require("core.franchise").current().chronicle.title
  local note = footer(actions.totals(history, rows))
  local width = math.max(vim.api.nvim_strwidth(lines[1]) + 1, #note + 2)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    style = "minimal",
    border = require("core.skin").border(),
    width = math.min(width, vim.o.columns - 4),
    height = #lines,
    row = 3,
    col = math.floor((vim.o.columns - width) / 2),
    title = " " .. require("core.skin").title(title) .. " ",
    title_pos = "center",
    footer = note,
    footer_pos = "center",
  })
  for _, key in ipairs({ "q", "<Esc>" }) do
    vim.keymap.set("n", key, function()
      pcall(vim.api.nvim_win_close, win, true)
    end, { buffer = buf, nowait = true })
  end
end

function M.setup()
  define_highlights()
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("eldentree_chronicle", { clear = true }),
    callback = define_highlights,
  })
  vim.api.nvim_create_user_command(
    "Chronicle",
    M.open,
    { desc = "The weeks you fought, as a grid" }
  )
  vim.keymap.set("n", "<leader>uj", M.open, { desc = "Chronicle" })
end

return M
