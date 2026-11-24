-- The toast a feat pops when it unlocks: a small card that slides in at the bottom right, above
-- the statusline and away from the notifications at the top, stays a moment and leaves, one at a
-- time when several unlock together. Stilled motion (or an expedition) turns it into a plain
-- notification.
local motion = require("core.motion")

local M = {}

M.SLIDE_MS = 380
M.HOLD_MS = 4200
M.GAP_MS = 300

local ns = vim.api.nvim_create_namespace("eldentree_feats_toast")
local queue, showing = {}, false

--- Paints the toast's groups from the region's palette.
function M.define_highlights()
  local p = require("core.themes").palette()
  vim.api.nvim_set_hl(0, "EldenFeatHeader", { fg = p.yellow, bg = p.mantle, bold = true })
  vim.api.nvim_set_hl(0, "EldenFeatName", { fg = p.text, bg = p.mantle, bold = true })
  vim.api.nvim_set_hl(0, "EldenFeatDesc", { fg = p.subtext0, bg = p.mantle })
end

local function card(feat)
  local icon = require("core.hud.items").TROPHY_ICON
  local lines = {
    (" %s  %s "):format(icon, feat.header),
    " " .. feat.name .. " ",
    " " .. feat.desc .. " ",
  }
  local width = 0
  for _, line in ipairs(lines) do
    width = math.max(width, vim.api.nvim_strwidth(line))
  end
  return lines, width
end

-- the row that rests the card on the statusline, borders included
local function row_for(height)
  return math.max(0, vim.o.lines - vim.o.cmdheight - height - 3)
end

local function open(lines, width, col)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  for row, group in ipairs({ "EldenFeatHeader", "EldenFeatName", "EldenFeatDesc" }) do
    vim.api.nvim_buf_set_extmark(buf, ns, row - 1, 0, { line_hl_group = group })
  end
  local win = vim.api.nvim_open_win(buf, false, {
    relative = "editor",
    row = row_for(#lines),
    col = col,
    width = width,
    height = #lines,
    style = "minimal",
    border = require("core.skin").border(),
    focusable = false,
    zindex = 240,
    noautocmd = true,
  })
  vim.wo[win].winhighlight = "Normal:EldenFeatDesc"
  return win
end

local show_next

local function leave(win)
  vim.defer_fn(function()
    pcall(vim.api.nvim_win_close, win, true)
    vim.defer_fn(show_next, M.GAP_MS)
  end, M.HOLD_MS)
end

local function slide(win, width, height)
  local final = math.max(0, vim.o.columns - width - 3)
  local start = vim.o.columns
  motion.tween({
    duration = M.SLIDE_MS,
    easing = "out_cubic",
    on_frame = function(eased)
      if vim.api.nvim_win_is_valid(win) then
        local col = math.floor(start + (final - start) * eased + 0.5)
        vim.api.nvim_win_set_config(win, { relative = "editor", row = row_for(height), col = col })
      end
    end,
  })
end

show_next = function()
  local feat = table.remove(queue, 1)
  showing = feat ~= nil
  if not feat then
    return
  end
  local lines, width = card(feat)
  local win = open(lines, width, vim.o.columns)
  require("core.sound").play_first({ "trophy", "grace" })
  slide(win, width, #lines)
  leave(win)
end

--- Announces an unlocked feat, after the ones already waiting.
---@param feat { header: string, name: string, desc: string }
function M.push(feat)
  if not motion.enabled() then
    return vim.notify(feat.name .. ": " .. feat.desc, vim.log.levels.INFO, { title = feat.header })
  end
  table.insert(queue, feat)
  if not showing then
    show_next()
  end
end

return M
