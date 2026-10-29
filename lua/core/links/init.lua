-- Opens the links terminals print. The terminal never sends Cmd to nvim, so Ctrl+click opens the
-- link under the mouse, and <leader>to opens the last one printed in any terminal buffer.
-- Hovering a link underlines it, so you know it can be clicked. A file:line like the ones Claude
-- Code prints opens in the editor at that line, the way it does in a terminal outside nvim.
local actions = require("core.links.actions")

local M = {}

local ns = vim.api.nvim_create_namespace("eldentree_links")

-- the link underlined right now: { buf, row, link }
local hovered

local function open(url)
  if not url then
    vim.notify("No link here", vim.log.levels.WARN)
    return
  end
  vim.ui.open(url)
end

-- the window the file opens in: the last one used outside a terminal, or a new split
local function editor_window()
  local previous = vim.fn.win_getid(vim.fn.winnr("#"))
  local candidates = vim.list_extend({ previous }, vim.api.nvim_tabpage_list_wins(0))
  for _, win in ipairs(candidates) do
    local buf = vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win)
    if buf and vim.bo[buf].buftype == "" and vim.api.nvim_win_get_config(win).relative == "" then
      return win
    end
  end
  vim.cmd("leftabove vsplit")
  return vim.api.nvim_get_current_win()
end

local function open_file(link)
  vim.cmd.stopinsert()
  vim.api.nvim_set_current_win(editor_window())
  vim.cmd.edit(vim.fn.fnameescape(link.file))
  if link.row then
    local last = vim.api.nvim_buf_line_count(0)
    pcall(
      vim.api.nvim_win_set_cursor,
      0,
      { math.min(link.row, last), math.max((link.col or 1) - 1, 0) }
    )
    vim.cmd("normal! zz")
  end
end

-- a file reference only counts when the file is there, so a word with a dot is not a link
local function on_disk(link)
  if link.url then
    return link
  end
  local file = actions.resolve(link.path, vim.fn.getcwd())
  if vim.uv.fs_stat(file) then
    return vim.tbl_extend("force", link, { file = file })
  end
  return nil
end

-- the link the mouse rests on, only inside terminal buffers
local function link_under_mouse()
  local mouse = vim.fn.getmousepos()
  if mouse.winid == 0 or mouse.line == 0 then
    return nil
  end
  local buf = vim.api.nvim_win_get_buf(mouse.winid)
  if vim.bo[buf].buftype ~= "terminal" then
    return nil
  end
  local line = vim.api.nvim_buf_get_lines(buf, mouse.line - 1, mouse.line, false)[1]
  local link = line and actions.link_at(line, mouse.column)
  link = link and on_disk(link)
  return link and { buf = buf, row = mouse.line - 1, link = link }
end

--- Opens the link under the mouse.
function M.open_under_mouse()
  local target = link_under_mouse()
  if target and target.link.file then
    return open_file(target.link)
  end
  open(target and target.link.url)
end

local function same_link(a, b)
  return a and b and a.buf == b.buf and a.row == b.row and a.link.first == b.link.first
end

local function clear_hover()
  if hovered and vim.api.nvim_buf_is_valid(hovered.buf) then
    vim.api.nvim_buf_clear_namespace(hovered.buf, ns, 0, -1)
  end
  hovered = nil
end

local function show_hover()
  local target = link_under_mouse()
  if same_link(target, hovered) then
    return
  end
  clear_hover()
  if not target then
    return
  end
  pcall(vim.api.nvim_buf_set_extmark, target.buf, ns, target.row, target.link.first - 1, {
    end_col = target.link.last,
    hl_group = "EldenLink",
    priority = 200,
  })
  hovered = target
end

local function terminal_buffers()
  return vim.tbl_filter(function(buf)
    return vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buftype == "terminal"
  end, vim.api.nvim_list_bufs())
end

--- Opens the last link printed in a terminal, the current buffer first, then the newest terminal.
function M.open_last()
  local buffers = terminal_buffers()
  if vim.bo.buftype == "terminal" then
    table.insert(buffers, vim.api.nvim_get_current_buf())
  end
  -- newest buffers have the highest numbers, the current one went last on purpose
  for index = #buffers, 1, -1 do
    local url = actions.last_url(vim.api.nvim_buf_get_lines(buffers[index], 0, -1, false))
    if url then
      return open(url)
    end
  end
  open(nil)
end

--- Lets Ctrl+click open links inside a terminal buffer, and underlines them on hover.
---@param buf integer terminal buffer
function M.attach(buf)
  vim.keymap.set(
    { "n", "t" },
    "<C-LeftMouse>",
    M.open_under_mouse,
    { buffer = buf, desc = "Open link under the mouse" }
  )
  vim.keymap.set({ "n", "t" }, "<MouseMove>", function()
    -- extmarks cannot change while an expr mapping runs
    vim.schedule(show_hover)
    -- the move goes on to whoever else listens, like the program in the terminal
    return "<MouseMove>"
  end, { buffer = buf, expr = true, desc = "Underline the link under the mouse" })
end

local function define_highlights()
  local p = require("core.themes").palette()
  vim.api.nvim_set_hl(0, "EldenLink", { fg = p.blue, underline = true })
end

function M.setup()
  define_highlights()
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("eldentree_links", { clear = true }),
    callback = define_highlights,
  })
end

return M
