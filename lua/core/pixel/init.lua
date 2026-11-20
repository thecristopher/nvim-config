-- The tiny 8 bit sprite the region's character pops whenever something happens: a save, a commit,
-- a PR, a win. One sprite per region, in the lore's `pixels`, and a region without one stays quiet.
-- It steps through its frames in a small float at the top right of the window, on core/motion's
-- clock, and is gone in under half a second. Transparent pixels let the code behind show through.
-- Each region's rows and highlight groups are built once and reused until the colors change.
-- `vim.g.eldentree_pixels = false` turns it off, `:Pixel` previews.
local actions = require("core.pixel.actions")

local M = {}

local ns = vim.api.nvim_create_namespace("eldentree_pixel")

-- the sprite on screen, so a new one replaces it instead of stacking
local shown = { win = nil, buf = nil, tween = nil }

-- the region whose frames are drawn and painted, and those frames as rows of cells
local built = { region = nil, rows_by_frame = nil }

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

-- the region's frames as rows with their groups defined, built only when the region or colors change
local function frames_of_region()
  local region = require("core.themes").current().name
  if built.region == region then
    return built.rows_by_frame
  end
  local sprite = actions.sprite_for(require("core.franchise").current().pixels, region)
  local rows_by_frame = sprite
    and vim.tbl_map(function(frame)
      return actions.rows(frame, sprite.colors)
    end, sprite.frames)
  if rows_by_frame then
    define_groups(rows_by_frame)
  end
  built.region, built.rows_by_frame = region, rows_by_frame
  return rows_by_frame
end

local function placement(rows)
  local info = vim.fn.getwininfo(vim.api.nvim_get_current_win())[1]
  return info and actions.place(info, vim.api.nvim_strwidth(rows[1].text), #rows)
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

--- Pops the region's sprite, when it has one and the moment's chance comes up.
---@param moment string what happened ("saved", "felled", "great")
---@param opts? { always?: boolean } always skips the chance, for previews
function M.pop(moment, opts)
  opts = opts or {}
  if not enabled() or not (opts.always or actions.pops(moment, math.random())) then
    return
  end
  local rows_by_frame = frames_of_region()
  local place = rows_by_frame and placement(rows_by_frame[1])
  if not rows_by_frame or not place then
    return
  end
  M.hide()
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
  -- a colorscheme clears every group, so the next pop builds the region's sprite again
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = group,
    callback = function()
      built.region, built.rows_by_frame = nil, nil
    end,
  })
  vim.api.nvim_create_user_command("Pixel", function()
    M.pop("preview", { always = true })
  end, { desc = "Preview the region's 8 bit sprite" })
end

return M
