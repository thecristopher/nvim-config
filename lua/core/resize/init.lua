-- Resizing every window: borders light up with a handle that rides them while they move, a
-- keyboard mode moves the current window's borders, and a reset puts the layout back.
local actions = require("core.resize.actions")

local M = {}

local KEY = {
  move = vim.keycode("<MouseMove>"),
  press = vim.keycode("<LeftMouse>"),
  drag = vim.keycode("<LeftDrag>"),
  release = vim.keycode("<LeftRelease>"),
}
local ns = vim.api.nvim_create_namespace("eldentree_resize")

-- the borders lit right now, the winhighlight each lit window had, and the mouse along them
local lit = { borders = {}, saved = {}, along = nil }
-- handle floats and their buffers, one per lit border
local handles = {}
local dragging = false
local in_mode = false

local function define_highlights()
  local p = require("core.themes").palette()
  vim.api.nvim_set_hl(0, "EldenResizeHover", { fg = p.yellow, bg = p.base, bold = true })
  vim.api.nvim_set_hl(0, "EldenResizeHandle", { fg = p.base, bg = p.yellow, bold = true })
end

local function valid(win)
  return win and vim.api.nvim_win_is_valid(win)
end

local function info_of(win)
  return vim.fn.getwininfo(win)[1]
end

local function close_handle(i)
  local handle = handles[i]
  if handle and valid(handle.win) then
    vim.api.nvim_win_close(handle.win, true)
  end
  if handle then
    handle.win = nil
  end
end

---Draws a handle on a border, the mouse passes through it so the drag still works.
local function place_handle(i, border)
  handles[i] = handles[i] or {}
  local handle = handles[i]
  if not handle.buf or not vim.api.nvim_buf_is_valid(handle.buf) then
    handle.buf = vim.api.nvim_create_buf(false, true)
  end
  vim.api.nvim_buf_set_lines(handle.buf, 0, -1, false, { actions.HANDLES[border.edge] })
  local row, col = actions.handle_spot(border.edge, info_of(border.win), lit.along)
  local config = { relative = "editor", row = row, col = col, width = 1, height = 1 }
  if valid(handle.win) then
    return vim.api.nvim_win_set_config(handle.win, config)
  end
  handle.win = vim.api.nvim_open_win(
    handle.buf,
    false,
    vim.tbl_extend("force", config, {
      style = "minimal",
      border = "none",
      focusable = false,
      mouse = false,
      zindex = 250,
    })
  )
  vim.wo[handle.win].winhighlight = "Normal:EldenResizeHandle"
end

-- handles go wherever the lit borders are now, so they ride a border that moves
local function draw()
  local shown = 0
  for _, border in ipairs(lit.borders) do
    if valid(border.win) then
      shown = shown + 1
      place_handle(shown, border)
    end
  end
  for i = shown + 1, #handles do
    close_handle(i)
  end
end

---Lights these borders and puts out the rest, giving each window back its winhighlight.
---@param borders { win: integer, edge: "right"|"bottom" }[]
---@param along integer|nil mouse position along the border
local function light(borders, along)
  local wanted = {}
  for _, border in ipairs(borders) do
    wanted[border.win] = true
  end
  for win, saved in pairs(lit.saved) do
    if not wanted[win] then
      if valid(win) then
        vim.wo[win].winhighlight = saved
      end
      lit.saved[win] = nil
    end
  end
  for win in pairs(wanted) do
    if not lit.saved[win] then
      lit.saved[win] = vim.wo[win].winhighlight
      vim.wo[win].winhighlight = actions.with_separator(lit.saved[win], "EldenResizeHover")
    end
  end
  lit.borders, lit.along = borders, along
  draw()
end

local function along_for(edge, pos)
  return edge == "right" and pos.screenrow or pos.screencol
end

---The window across a border of win, nil at the edge of the editor.
local function neighbor(win, direction)
  return vim.api.nvim_win_call(win, function()
    local nr = vim.fn.winnr(direction)
    if nr == vim.fn.winnr() then
      return nil
    end
    return vim.fn.win_getid(nr)
  end)
end

local function update_hover()
  if dragging or in_mode then
    return
  end
  local pos = vim.fn.getmousepos()
  local win = pos.winid
  if win == 0 or vim.api.nvim_win_get_config(win).relative ~= "" then
    return light({})
  end
  local edge = actions.edge_at(pos, info_of(win))
  -- the lowest window's bottom edge is the statusline, nothing sits across it to resize against
  if not edge or not neighbor(win, actions.ACROSS[edge]) then
    return light({})
  end
  light({ { win = win, edge = edge } }, along_for(edge, pos))
end

local function follow_drag()
  local border = lit.borders[1]
  if not border then
    return
  end
  lit.along = along_for(border.edge, vim.fn.getmousepos())
  draw()
end

local function width_range(win)
  return actions.width_range(vim.bo[vim.api.nvim_win_get_buf(win)].filetype, vim.o.columns)
end

-- the tree goes back inside its range after anything moved it, except while Claude is fullscreen
local function fit_all()
  if require("core.claude_panel").is_fullscreen() then
    return
  end
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_get_config(win).relative == "" then
      local width = actions.fitted(vim.api.nvim_win_get_width(win), width_range(win))
      if width then
        vim.api.nvim_win_set_width(win, width)
      end
    end
  end
end

local function step(win, move)
  if move.side == "width" then
    local least, most = width_range(win)
    vim.api.nvim_win_set_width(
      win,
      actions.stepped(vim.api.nvim_win_get_width(win), move.steps, least, most)
    )
  else
    local height = actions.stepped(vim.api.nvim_win_get_height(win), move.steps, 1, vim.o.lines)
    vim.api.nvim_win_set_height(win, height)
  end
  fit_all()
end

local function tree_width()
  local ok, neotree = pcall(require, "neo-tree")
  local width = ok and neotree.config and neotree.config.window and neotree.config.window.width
  return type(width) == "number" and width or nil
end

--- Puts the layout back: the tree and the Claude panel at their default widths, the rest equal.
function M.reset()
  local panel = require("core.claude_panel")
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local filetype = vim.bo[vim.api.nvim_win_get_buf(win)].filetype
    if filetype == "neo-tree" and tree_width() then
      vim.api.nvim_win_set_width(win, tree_width())
    elseif win == panel.window() then
      vim.api.nvim_win_set_width(win, panel.default_width())
    end
  end
  vim.cmd("wincmd =")
  draw()
end

---The borders hjkl move for win: its own right and bottom ones, or the ones on the other side
---when it sits against the edge of the editor.
local function moving_borders(win)
  local borders = {}
  local right = neighbor(win, "l") and win or neighbor(win, "h")
  if right then
    table.insert(borders, { win = right, edge = "right" })
  end
  local bottom = neighbor(win, "j") and win or neighbor(win, "k")
  if bottom then
    table.insert(borders, { win = bottom, edge = "bottom" })
  end
  return borders
end

local HINT = "Resize  h l width  j k height  H J K L faster  = reset  Esc done"

local function read_key()
  local ok, key = pcall(vim.fn.getcharstr)
  return ok and vim.fn.keytrans(key) or "<Esc>"
end

--- Moves the current window's borders from the keyboard until Esc, q or Enter.
function M.mode()
  local win = vim.api.nvim_get_current_win()
  in_mode = true
  while valid(win) do
    light(moving_borders(win))
    vim.cmd.redraw()
    vim.api.nvim_echo({ { HINT, "EldenResizeHover" } }, false, {})
    local key = read_key()
    if actions.DONE[key] then
      break
    end
    if key == "=" then
      M.reset()
    elseif actions.KEYS[key] then
      step(win, actions.KEYS[key])
    end
  end
  in_mode = false
  light({})
  vim.api.nvim_echo({ { "" } }, false, {})
end

local function on_key(key)
  if key == KEY.move then
    vim.schedule(update_hover)
  elseif key == KEY.press then
    -- a press on a lit border starts dragging it, the handle rides along until release
    dragging = #lit.borders > 0 and not in_mode
  elseif key == KEY.drag and dragging then
    vim.schedule(follow_drag)
  elseif key == KEY.release and dragging then
    dragging = false
    vim.schedule(update_hover)
  end
end

function M.setup()
  define_highlights()
  local group = vim.api.nvim_create_augroup("eldentree_resize", { clear = true })
  vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = define_highlights })
  vim.api.nvim_create_autocmd("WinResized", {
    group = group,
    callback = function()
      fit_all()
      draw()
    end,
  })
  vim.api.nvim_create_autocmd("WinClosed", {
    group = group,
    callback = function()
      vim.schedule(draw)
    end,
  })
  -- the terminal changed size, so the defaults (a share of the editor) are worth recomputing
  vim.api.nvim_create_autocmd("VimResized", {
    group = group,
    callback = function()
      if require("core.claude_panel").is_fullscreen() then
        return vim.schedule(draw)
      end
      vim.schedule(M.reset)
    end,
  })
  -- on_key instead of mouse mappings, so buffer mappings like the link hover keep theirs
  vim.on_key(on_key, ns)
  vim.api.nvim_create_user_command("Resize", M.mode, { desc = "Move the current window's borders" })
  vim.api.nvim_create_user_command("ResizeReset", M.reset, { desc = "Put the window layout back" })
end

return M
