-- Tiny 8 bit sprites the region's character pops when something happens: a hex on a save, a crown
-- on a win. The sprites live in the lore's `pixels`, keyed by region, and a region without one
-- stays quiet. Each sprite steps through its frames in a small float at the top right of the
-- window, on core/motion's clock, and is gone in under a second. Transparent pixels let the code
-- behind show through. `vim.g.eldentree_pixels = false` turns it off, `:Pixel <moment>` previews.
local actions = require("core.pixel.actions")

local M = {}

local ns = vim.api.nvim_create_namespace("eldentree_pixel")

-- the sprite on screen, so a new one replaces it instead of stacking
local shown = { win = nil, buf = nil, tween = nil }

local function enabled()
  return vim.g.eldentree_pixels ~= false and require("core.motion").enabled()
end

--- Clears the sprite on screen, if any.
function M.hide()
  if shown.tween then
    shown.tween:stop()
  end
  if shown.win and vim.api.nvim_win_is_valid(shown.win) then
    pcall(vim.api.nvim_win_close, shown.win, true)
  end
  shown.win, shown.tween = nil, nil
end

local function scratch()
  if shown.buf and vim.api.nvim_buf_is_valid(shown.buf) then
    return shown.buf
  end
  shown.buf = vim.api.nvim_create_buf(false, true)
  vim.bo[shown.buf].bufhidden = "hide"
  return shown.buf
end

local function open_float(place)
  local ok, win = pcall(vim.api.nvim_open_win, scratch(), false, {
    relative = "editor",
    row = place.row,
    col = place.col,
    width = place.width,
    height = place.height,
    style = "minimal",
    border = "none",
    focusable = false,
    mouse = false,
    -- above the banners, a win pops its crown while the banner still reads
    zindex = 260,
    noautocmd = true,
  })
  if not ok then
    return nil
  end
  -- empty cells blend all the way through, painted ones set their own blend of 0
  vim.wo[win].winblend = 100
  vim.wo[win].winhighlight = "Normal:EldenPixelClear"
  return win
end

-- one group per pair of slots the sprite paints, read from the palette in use
local function define_groups(rows_by_frame)
  local palette = require("core.themes").palette()
  vim.api.nvim_set_hl(0, "EldenPixelClear", { bg = palette.base, blend = 100 })
  for _, rows in ipairs(rows_by_frame) do
    for _, row in ipairs(rows) do
      for _, mark in ipairs(row.marks) do
        vim.api.nvim_set_hl(0, actions.group(mark.fg, mark.bg), {
          fg = palette[mark.fg],
          bg = palette[mark.bg],
          blend = 0,
        })
      end
    end
  end
end

local function paint(rows)
  local buf = scratch()
  local lines = vim.tbl_map(function(row)
    return row.text
  end, rows)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for index, row in ipairs(rows) do
    for _, mark in ipairs(row.marks) do
      vim.api.nvim_buf_set_extmark(buf, ns, index - 1, mark.start, {
        end_col = mark.finish,
        hl_group = actions.group(mark.fg, mark.bg),
      })
    end
  end
end

local function sprite_of(moment)
  local region = require("core.themes").current()
  local pixels = require("core.franchise").current().pixels
  return actions.sprite_for(pixels, region.name, moment)
end

local function placement(frames)
  local info = vim.fn.getwininfo(vim.api.nvim_get_current_win())[1]
  local width, height = actions.size(frames)
  return info and actions.place(info, width, height)
end

local function animate(rows_by_frame)
  local count = #rows_by_frame
  local last
  shown.tween = require("core.motion").tween({
    duration = count * actions.FRAME_MS,
    easing = "linear",
    on_frame = function(_, raw)
      local index = actions.frame_at(raw * count * actions.FRAME_MS, count) or count
      if index ~= last then
        last = index
        paint(rows_by_frame[index])
      end
    end,
    on_done = M.hide,
  })
end

--- Pops the region's sprite for a moment, when it has one and the moment's chance comes up.
---@param moment string what happened ("saved", "felled", "great")
---@param opts? { always?: boolean } always skips the chance, for previews
function M.pop(moment, opts)
  opts = opts or {}
  if not enabled() or not (opts.always or actions.pops(moment, math.random())) then
    return
  end
  local sprite = sprite_of(moment)
  if not sprite then
    return
  end
  local place = placement(sprite.frames)
  if not place then
    return
  end
  local rows_by_frame = vim.tbl_map(function(frame)
    return actions.rows(frame, sprite.colors)
  end, sprite.frames)
  M.hide()
  define_groups(rows_by_frame)
  paint(rows_by_frame[1])
  shown.win = open_float(place)
  if shown.win then
    animate(rows_by_frame)
  end
end

local function saved_a_file(args)
  return vim.bo[args.buf].buftype == "" and vim.api.nvim_buf_get_name(args.buf) ~= ""
end

function M.setup()
  local group = vim.api.nvim_create_augroup("eldentree_pixel", { clear = true })
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    callback = function(args)
      -- :w fires this from the command line, the sprite pops once back in the window
      if saved_a_file(args) then
        vim.schedule(function()
          M.pop("saved")
        end)
      end
    end,
  })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = { "EldentreeMotion", "EldentreeFranchise" },
    callback = M.hide,
  })
  vim.api.nvim_create_user_command("Pixel", function(cmd)
    M.pop(cmd.args ~= "" and cmd.args or "saved", { always = true })
  end, {
    nargs = "?",
    complete = function()
      return { "saved", "felled", "great" }
    end,
    desc = "Preview the region's 8 bit sprite for a moment",
  })
end

return M
