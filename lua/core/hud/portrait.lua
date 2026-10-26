-- The champion's portrait inside the HUD: a small float over the space the view leaves for it.
-- chafa draws it in half blocks into a terminal buffer, or snacks draws real pixels where the
-- terminal speaks the kitty graphics protocol. Renders are cached so moving around never redraws them.
-- Each image lives in its own slot ("hud" by default, "music" for the album cover), so drawing or
-- closing one never takes another off the screen.
local M = {}

local rendered = {}
local views = {}

local function close_window(view)
  if not view then
    return
  end
  pcall(vim.api.nvim_win_close, view.win, true)
  pcall(vim.api.nvim_buf_delete, view.buf, { force = true })
end

--- Removes the image in a slot.
---@param slot string|nil defaults to "hud"
function M.close(slot)
  slot = slot or "hud"
  close_window(views[slot])
  views[slot] = nil
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

-- snacks sends each image to the terminal once, so after the terminal reloads it has to be told
-- to send it again instead of pointing at a picture the terminal may have dropped
local function send_again(file)
  pcall(function()
    Snacks.image.image.new(file).sent = false
  end)
end

local function draw_with_pixels(view, file, anchor, fresh)
  if fresh then
    send_again(file)
  end
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

local function open_view(parent, anchor, key, slot)
  local view = { key = key, buf = vim.api.nvim_create_buf(false, true) }
  vim.bo[view.buf].bufhidden = "wipe"
  view.win = open_float(parent, anchor, view.buf)
  -- snacks encodes which image goes in each cell in its color, any blend scrambles it into black
  vim.wo[view.win].winblend = 0
  views[slot] = view
  return view
end

local function still_current(view, slot)
  return views[slot] == view
    and vim.api.nvim_buf_is_valid(view.buf)
    and vim.api.nvim_win_is_valid(view.win)
end

--- Shows an image at an anchor inside a window, unless the same one is already there.
---@param parent integer window the image sits in
---@param file string image path
---@param anchor { row: integer, col: integer, width: integer, height: integer } zero based, in the parent window
---@param slot string|nil defaults to "hud"
---@param opts { fresh: boolean|nil }|nil fresh sends the image to the terminal again
function M.show(parent, file, anchor, slot, opts)
  slot = slot or "hud"
  opts = opts or {}
  local key = ("%s|%d:%d|%d"):format(cache_key(file, anchor), anchor.row, anchor.col, parent)
  local shown = views[slot]
  if shown and shown.key == key and vim.api.nvim_win_is_valid(shown.win) then
    return
  end
  M.close(slot)
  if vim.fn.filereadable(file) == 0 or not vim.api.nvim_win_is_valid(parent) then
    return
  end
  local view = open_view(parent, anchor, key, slot)
  view.drawn = { parent = parent, file = file, anchor = anchor }
  if
    require("core.terminal").can_draw(file) and draw_with_pixels(view, file, anchor, opts.fresh)
  then
    view.pixels = true
    return
  end
  if vim.fn.executable("chafa") == 0 then
    return
  end
  -- a failed pixel placement may leave its buffer behind or take it away, chafa starts on a clean one
  if not still_current(view, slot) or vim.api.nvim_buf_line_count(view.buf) > 1 then
    M.close(slot)
    view = open_view(parent, anchor, key, slot)
  end
  draw_with_chafa(view, file, anchor)
end

-- a terminal reload can drop the pictures it was showing, so every pixel image is drawn again
local function redraw_pixels()
  local slots = {}
  for slot, view in pairs(views) do
    if view.pixels then
      slots[#slots + 1] = slot
    end
  end
  for _, slot in ipairs(slots) do
    local drawn = views[slot].drawn
    M.close(slot)
    M.show(drawn.parent, drawn.file, drawn.anchor, slot, { fresh = true })
  end
end

vim.api.nvim_create_autocmd("User", {
  group = vim.api.nvim_create_augroup("eldentree_portrait", { clear = true }),
  pattern = "EldentreeTerminalSettled",
  callback = redraw_pixels,
})

return M
