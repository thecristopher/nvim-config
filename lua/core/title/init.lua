-- The title screen: the franchise's name in big letters over a dark veil, once a day per franchise
-- and every time :Franchise switches worlds. Any key lifts it and is swallowed, like the rest screen.
-- :Title shows it on demand, vim.g.eldentree_title = false keeps it from showing on its own.
local actions = require("core.title.actions")
local banner = require("core.banner.actions")
local motion = require("core.motion")
local color = require("core.motion.actions")

local M = {}

local ns = vim.api.nvim_create_namespace("eldentree_title")
local state_file = vim.fn.stdpath("state") .. "/eldentree_title"
local scene

local function lore()
  return require("core.franchise").current()
end

local function paint_groups(elapsed)
  local p = require("core.themes").palette()
  local veil = color.to_int(p.crust)
  local title = color.to_int(scene.title.color)
  local alpha = actions.alpha(elapsed)
  local ground = color.mix(color.to_int(p.base), veil, alpha)
  for level = 1, actions.LEVELS do
    local glint = color.mix(title, 0xFFFFFF, (level - 1) / (actions.LEVELS - 1) * 0.65)
    vim.api.nvim_set_hl(
      0,
      "EldenTitle" .. level,
      { fg = color.mix(veil, glint, alpha), bg = ground, bold = true }
    )
  end
  vim.api.nvim_set_hl(
    0,
    "EldenTitleDrip",
    { fg = color.mix(veil, color.mix(title, 0x000000, 0.3), alpha), bg = ground }
  )
  vim.api.nvim_set_hl(
    0,
    "EldenTitleSub",
    { fg = color.mix(veil, color.to_int(p.subtext0), alpha), bg = ground, italic = true }
  )
  local blink = math.floor(elapsed / 700) % 2 == 0 and alpha or alpha * 0.35
  vim.api.nvim_set_hl(
    0,
    "EldenTitleHint",
    { fg = color.mix(veil, color.to_int(p.overlay2), blink), bg = ground }
  )
  -- an opaque veil fading from the region's base into crust: a blended one lets every character
  -- of the screen underneath show through its blank cells and tangle with the letters
  vim.api.nvim_set_hl(0, "EldenTitleVeil", { bg = ground })
end

-- one row of block letters as chunks, every solid cell taking the shimmer's level at its column
local function row_chunks(text, elapsed)
  local chunks, width = {}, vim.fn.strdisplaywidth(text)
  for col, char in ipairs(vim.fn.split(text, "\\zs")) do
    local level = scene.title.style == "shimmer" and actions.shimmer_level(col - 1, elapsed, width)
      or 1
    local group = "EldenTitle" .. level
    local last = chunks[#chunks]
    if last and last[2] == group then
      last[1] = last[1] .. char
    else
      table.insert(chunks, { char, group })
    end
  end
  return chunks
end

local function put(row, col, chunks)
  if row < 0 or row >= scene.height then
    return
  end
  vim.api.nvim_buf_set_extmark(
    scene.buf,
    ns,
    row,
    0,
    { virt_text = chunks, virt_text_win_col = col, priority = 100 }
  )
end

local function draw_drips(elapsed)
  for _, drip in ipairs(scene.drips) do
    local length = actions.drip_length(drip.depth, elapsed)
    for depth = 1, length do
      put(
        scene.top + #scene.rows + depth - 1,
        scene.col + drip.col,
        { { depth == length and "▾" or "┃", "EldenTitleDrip" } }
      )
    end
  end
end

local function draw(elapsed)
  if not vim.api.nvim_win_is_valid(scene.win) then
    return false
  end
  if elapsed > actions.AUTO_CLOSE_MS then
    return M.close()
  end
  paint_groups(elapsed)
  vim.api.nvim_buf_clear_namespace(scene.buf, ns, 0, -1)
  for index, text in ipairs(scene.rows) do
    put(scene.top + index - 1, scene.col, row_chunks(text, elapsed))
  end
  if scene.title.style == "drip" then
    draw_drips(elapsed)
  end
  local sub = banner.spaced(scene.title.subtitle or "")
  put(
    scene.top + #scene.rows + actions.DRIP_DEPTH + 1,
    banner.center_col(scene.width, vim.fn.strdisplaywidth(sub)),
    { { sub, "EldenTitleSub" } }
  )
  local hint = "press any key"
  put(scene.height - 3, banner.center_col(scene.width, #hint), { { hint, "EldenTitleHint" } })
end

-- block letters when they fit, the letterspaced name when the window is too narrow for them
local function title_rows(text, width)
  local rows = actions.big(text)
  if vim.fn.strdisplaywidth(rows[1]) <= width - 4 then
    return rows
  end
  return { banner.spaced(text) }
end

local function open_scene()
  local width, height = vim.o.columns, vim.o.lines
  scene = { width = width, height = height, title = lore().skin.title }
  scene.rows = title_rows(scene.title.text, width)
  scene.drips = #scene.rows > 1 and actions.drips(scene.rows[#scene.rows]) or {}
  scene.top = math.floor(height * 0.32)
  scene.col = banner.center_col(width, vim.fn.strdisplaywidth(scene.rows[1]))

  scene.buf = vim.api.nvim_create_buf(false, true)
  vim.bo[scene.buf].bufhidden = "wipe"
  local blank, lines = (" "):rep(width), {}
  for row = 1, height do
    lines[row] = blank
  end
  vim.api.nvim_buf_set_lines(scene.buf, 0, -1, false, lines)
  scene.win = vim.api.nvim_open_win(scene.buf, false, {
    relative = "editor",
    row = 0,
    col = 0,
    width = width,
    height = height,
    style = "minimal",
    border = "none",
    focusable = false,
    zindex = 260,
    noautocmd = true,
  })
  -- floats inherit the global winblend, and any blend lets the screen underneath show through
  vim.wo[scene.win].winblend = 0
  vim.wo[scene.win].winhighlight = "Normal:EldenTitleVeil"
end

--- Lifts the title screen.
function M.close()
  if not scene then
    return
  end
  if scene.loop then
    scene.loop:stop()
  end
  -- the music belongs to the title screen, so it stops when the screen lifts
  if scene.sound then
    pcall(scene.sound.kill, scene.sound, 15)
  end
  pcall(vim.api.nvim_win_close, scene.win, true)
  pcall(vim.api.nvim_buf_delete, scene.buf, { force = true })
  scene = nil
  return false
end

--- Shows the franchise's title screen, unless animations are stilled.
function M.show()
  if scene or not motion.enabled() then
    return
  end
  open_scene()
  scene.sound = require("core.sound").play("title")
  scene.loop = motion.loop({ interval = 50, on_tick = draw })
end

local function remember_today()
  pcall(vim.fn.writefile, { os.date("%Y-%m-%d") .. " " .. lore().name }, state_file)
end

local function first_today()
  local ok, lines = pcall(vim.fn.readfile, state_file, "", 1)
  return not actions.shown_today(ok and lines[1] or nil, os.date("%Y-%m-%d"), lore().name)
end

--- Tells whether the title screen still has to show today for this franchise.
---@return boolean
function M.due_today()
  return vim.g.eldentree_title ~= false and first_today()
end

local function show_and_remember()
  if vim.g.eldentree_title == false then
    return
  end
  remember_today()
  M.show()
end

function M.setup()
  vim.on_key(function()
    if not scene then
      return
    end
    vim.schedule(M.close)
    return ""
  end, ns)

  local group = vim.api.nvim_create_augroup("eldentree_title", { clear = true })
  vim.api.nvim_create_autocmd("UIEnter", {
    group = group,
    callback = function()
      if first_today() then
        vim.defer_fn(show_and_remember, 400)
      end
    end,
  })
  vim.api.nvim_create_autocmd(
    "User",
    { group = group, pattern = "EldentreeFranchise", callback = show_and_remember }
  )
  vim.api.nvim_create_autocmd("VimResized", { group = group, callback = M.close })
  vim.api.nvim_create_user_command("Title", M.show, { desc = "Show the franchise's title screen" })
end

return M
