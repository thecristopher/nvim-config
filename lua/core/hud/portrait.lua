-- The champion's portrait inside the HUD: a small float over the space the view leaves for it.
-- chafa draws it in half blocks into a terminal buffer, or snacks draws real pixels where the
-- terminal speaks the kitty graphics protocol. Renders are cached so moving around never redraws them.
local M = {}

local rendered = {}
local current

local function close_window(view)
  if not view then
    return
  end
  pcall(vim.api.nvim_win_close, view.win, true)
  pcall(vim.api.nvim_buf_delete, view.buf, { force = true })
end

--- Removes the portrait.
function M.close()
  close_window(current)
  current = nil
end

local function cache_key(file, anchor)
  local stat = vim.uv.fs_stat(file)
  return ("%s|%d|%dx%d"):format(file, stat and stat.mtime.sec or 0, anchor.width, anchor.height)
end

local function open_float(parent, anchor, buf)
  return vim.api.nvim_open_win(buf, false, {
    relative = "win",
    win = parent,
    row = anchor.row,
    col = anchor.col,
    width = anchor.width,
    height = anchor.height,
    style = "minimal",
    border = "none",
    focusable = false,
    zindex = 45,
    noautocmd = true,
  })
end

local function draw_with_chafa(view, file, anchor)
  local ok, channel = pcall(vim.api.nvim_open_term, view.buf, {})
  if not ok then
    return
  end
  local key = cache_key(file, anchor)
  local function send(output)
    if vim.api.nvim_buf_is_valid(view.buf) then
      pcall(vim.api.nvim_chan_send, channel, (output:gsub("\n$", "")))
    end
  end
  if rendered[key] then
    return send(rendered[key])
  end
  local size = ("%dx%d"):format(anchor.width, anchor.height)
  vim.system(
    {
      "chafa",
      "--format=symbols",
      "--symbols=half",
      "--size=" .. size,
      "--colors=full",
      "--work=9",
      file,
    },
    {},
    vim.schedule_wrap(function(result)
      if result.code ~= 0 then
        return
      end
      rendered[key] = result.stdout
      send(result.stdout)
    end)
  )
end

local function draw_with_pixels(view, file, anchor)
  local blank = {}
  for row = 1, anchor.height do
    blank[row] = (" "):rep(anchor.width)
  end
  vim.api.nvim_buf_set_lines(view.buf, 0, -1, false, blank)
  local ok = pcall(Snacks.image.placement.new, view.buf, file, {
    pos = { 1, 0 },
    inline = true,
    width = anchor.width,
    height = anchor.height,
  })
  return ok
end

local function open_view(parent, anchor, key)
  local view = { key = key, buf = vim.api.nvim_create_buf(false, true) }
  vim.bo[view.buf].bufhidden = "wipe"
  view.win = open_float(parent, anchor, view.buf)
  current = view
  return view
end

local function still_current(view)
  return current == view
    and vim.api.nvim_buf_is_valid(view.buf)
    and vim.api.nvim_win_is_valid(view.win)
end

--- Shows a portrait at an anchor inside a window, unless the same one is already there.
---@param parent integer window the HUD lives in
---@param file string image path
---@param anchor { row: integer, col: integer, width: integer, height: integer } zero based, in the parent window
function M.show(parent, file, anchor)
  local key = cache_key(file, anchor) .. "|" .. anchor.row .. ":" .. anchor.col
  if current and current.key == key and vim.api.nvim_win_is_valid(current.win) then
    return
  end
  M.close()
  if vim.fn.filereadable(file) == 0 or not vim.api.nvim_win_is_valid(parent) then
    return
  end
  local view = open_view(parent, anchor, key)
  if require("core.terminal").supports_images() and draw_with_pixels(view, file, anchor) then
    return
  end
  if vim.fn.executable("chafa") == 0 then
    return
  end
  -- a failed pixel placement may leave its buffer behind or take it away, chafa starts on a clean one
  if not still_current(view) or vim.api.nvim_buf_line_count(view.buf) > 1 then
    M.close()
    view = open_view(parent, anchor, key)
  end
  draw_with_chafa(view, file, anchor)
end

return M
