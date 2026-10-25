-- :Map opens the project map in a float, one row per room. Red rooms still hide errors or TODOs,
-- blue rooms are cleared, and <CR> walks into one with the file picker.
local actions = require("core.map.actions")

local M = {}

local ns = vim.api.nvim_create_namespace("eldentree_map")

local function define_highlights()
  local p = require("core.themes").palette()
  vim.api.nvim_set_hl(0, "EldenMapLeft", { fg = p.red, bold = true })
  vim.api.nvim_set_hl(0, "EldenMapCleared", { fg = p.sapphire, bold = true })
  vim.api.nvim_set_hl(0, "EldenMapPath", { fg = p.overlay1, italic = true })
end

local function git_lines(root, args)
  local result =
    vim.system(vim.list_extend({ "git", "-C", root }, args), { text = true }):wait(5000)
  return result.code == 0 and result.stdout or ""
end

local function open_errors()
  local errors = {}
  for _, diagnostic in ipairs(vim.diagnostic.get(nil, { severity = vim.diagnostic.severity.ERROR })) do
    local path = vim.api.nvim_buf_get_name(diagnostic.bufnr)
    errors[path] = (errors[path] or 0) + 1
  end
  return errors
end

local function survey(root)
  local files = vim.split(git_lines(root, { "ls-files" }), "\n", { trimempty = true })
  local todos = actions.parse_counts(git_lines(root, { "grep", "-I", "-c", "-E", "TODO|FIXME" }))
  return actions.rooms(root, files, todos, open_errors())
end

local function render(rooms)
  local name_width = 0
  for _, room in ipairs(rooms) do
    name_width = math.max(name_width, vim.api.nvim_strwidth(room.name))
  end
  local lines, marks = {}, {}
  for index, room in ipairs(rooms) do
    local glyph = room.cleared and "■" or "□"
    local name = room.name .. (" "):rep(name_width - vim.api.nvim_strwidth(room.name))
    local line = (" %s %s  %s  %s"):format(glyph, name, room.key, actions.leftovers(room))
    lines[index] = line
    local name_end = 1 + #glyph + 1 + #name
    marks[index] = {
      { 0, name_end, room.cleared and "EldenMapCleared" or "EldenMapLeft" },
      { name_end + 2, name_end + 2 + #room.key, "EldenMapPath" },
    }
  end
  return lines, marks
end

local function open_float(rooms, root)
  local lines, marks = render(rooms)
  local width = 20
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

  local cleared, total = actions.progress(rooms)
  local words = require("core.franchise").current().words
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    style = "minimal",
    border = require("core.skin").border(),
    width = math.min(width, vim.o.columns - 4),
    height = math.min(#lines, vim.o.lines - 6),
    row = 2,
    col = math.floor((vim.o.columns - width) / 2),
    title = " " .. require("core.skin").title(
      ("%s · %s"):format(words.map, require("core.themes").current().title)
    ) .. " ",
    title_pos = "center",
    footer = (" %d of %d rooms cleared "):format(cleared, total),
    footer_pos = "center",
  })
  vim.wo[win].cursorline = true

  local close = function()
    pcall(vim.api.nvim_win_close, win, true)
  end
  vim.keymap.set("n", "q", close, { buffer = buf, nowait = true })
  vim.keymap.set("n", "<Esc>", close, { buffer = buf, nowait = true })
  vim.keymap.set("n", "<CR>", function()
    local room = rooms[vim.api.nvim_win_get_cursor(win)[1]]
    close()
    Snacks.picker.files({ cwd = root .. "/" .. room.key })
  end, { buffer = buf, nowait = true })
end

--- Returns the rooms of a project, red or blue, for anything else that wants to draw them.
---@param root string repo root
---@return table[]
function M.rooms(root)
  return survey(root)
end

--- Opens the map of the project you stand in.
function M.open()
  local root = require("core.repos").root()
  if not root then
    return vim.notify(
      "No map here, this folder is not in a repo",
      vim.log.levels.INFO,
      { title = "Map" }
    )
  end
  local rooms = survey(root)
  if #rooms == 0 then
    return vim.notify(
      "This project has no rooms yet, only files at its root",
      vim.log.levels.INFO,
      { title = "Map" }
    )
  end
  open_float(rooms, root)
end

function M.setup()
  define_highlights()
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("eldentree_map", { clear = true }),
    callback = define_highlights,
  })
  vim.api.nvim_create_user_command("Map", M.open, { desc = "Open the project map" })
end

return M
