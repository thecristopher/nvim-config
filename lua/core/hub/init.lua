-- Brings the Roundtable Hold dashboard to life: shimmering gold headers, rising embers and a
-- player message written in by an invisible quill. Everything is extmarks on top of snacks' render.
local actions = require("core.hub.actions")
local motion  = require("core.motion")
local color   = require("core.motion.actions")

local M = {}

local ns = vim.api.nvim_create_namespace("eldentree_hub")
local FRAME_MS = 40

-- the rows worth gilding, matched by the ornaments and the character name the dashboard draws
local function gilded_marks()
  return { "◈", "R O U N D", actions.spaced(require("core.themes").current().character) }
end

local session

function M.message()
  if not M.current_message then
    math.randomseed(vim.uv.hrtime() % 2 ^ 31)
    M.current_message = actions.pick_message(math.random)
  end
  return M.current_message
end

local function define_highlights()
  local p = require("core.themes").palette()
  local gold, bright = color.to_int(p.yellow), color.to_int(p.text)
  local white = color.mix(bright, 0xFFFFFF, 0.6)
  for level = 1, actions.SHIMMER_LEVELS do
    local t = level / actions.SHIMMER_LEVELS
    vim.api.nvim_set_hl(0, "EldenShimmer" .. level, { fg = color.mix(gold, white, t), bold = true })
  end
  local base, ember, flare = color.to_int(p.base), color.to_int(p.peach), color.to_int(p.yellow)
  for level = 1, actions.EMBER_LEVELS do
    local t = level / actions.EMBER_LEVELS
    local hue = color.mix(ember, flare, t)
    vim.api.nvim_set_hl(0, "EldenEmber" .. level, { fg = color.mix(base, hue, 0.25 + 0.75 * t) })
  end
  vim.api.nvim_set_hl(0, "EldenQuill", { fg = p.yellow, bold = true })
end

-- per row lists of { byte_start, byte_end, col, char } so drawing never re-parses lines
local function index_buffer(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local rows = {}
  local marks = gilded_marks()
  for row, line in ipairs(lines) do
    local cells, chars, col = {}, {}, 0
    local starts = vim.str_utf_pos(line)
    for index, start in ipairs(starts) do
      local stop = (starts[index + 1] or #line + 1) - 1
      local char = line:sub(start, stop)
      local width = vim.api.nvim_strwidth(char)
      table.insert(chars, { start - 1, stop, col, char })
      table.insert(cells, { char, width })
      col = col + width
    end
    local gilded = false
    for _, mark in ipairs(marks) do
      if line:find(mark, 1, true) then gilded = true end
    end
    rows[row] = { line = line, chars = chars, taken = actions.occupied(cells), gilded = gilded }
  end
  return rows
end

local function find_message(rows, text)
  for row, info in ipairs(rows) do
    local start = info.line:find(text, 1, true)
    if start then return row, vim.api.nvim_strwidth(info.line:sub(1, start - 1)) end
  end
end

local function draw_shimmer(s, elapsed)
  for row, info in ipairs(s.rows) do
    if info.gilded then
      for _, char in ipairs(info.chars) do
        if char[4] ~= " " then
          local level = actions.shimmer_level(char[3], row, elapsed, s.width)
          if level > 0 then
            vim.api.nvim_buf_set_extmark(s.buf, ns, row - 1, char[1], {
              end_col = char[2], hl_group = "EldenShimmer" .. level, priority = 300,
            })
          end
        end
      end
    end
  end
end

local function under_quill(s, row, col)
  local mask = s.quill_mask
  return mask and row == mask.row and col >= mask.from and col <= mask.to
end

local function draw_embers(s, dt)
  local height = math.min(#s.rows, vim.api.nvim_win_get_height(s.win))
  local alive = {}
  for _, ember in ipairs(s.embers) do
    actions.step_ember(ember, dt)
    if actions.ember_alive(ember) then table.insert(alive, ember) end
  end
  while #alive < actions.ember_budget(s.width, height) and math.random() < 0.35 do
    table.insert(alive, actions.spawn_ember(math.random, s.width, height))
  end
  s.embers = alive

  for _, ember in ipairs(alive) do
    local row, col = math.floor(ember.y), math.floor(ember.x)
    local info = s.rows[row + 1]
    -- embers drift behind the text instead of scribbling over it
    if info and col >= 0 and col < s.width and not info.taken[col] and not under_quill(s, row, col) then
      local glyph, level = actions.ember_look(ember)
      vim.api.nvim_buf_set_extmark(s.buf, ns, row, 0, {
        virt_text = { { glyph, "EldenEmber" .. level } },
        virt_text_win_col = col,
        priority = 100,
      })
    end
  end
end

local function draw_quill(s, elapsed)
  local text = '"' .. M.message() .. '"'
  local row, col = find_message(s.rows, text)
  s.quill_mask = nil
  if not row then return end
  local length = vim.fn.strchars(text)
  if actions.quill_done(length, elapsed) then return end

  local typed = actions.typed(length, elapsed)
  local quill = actions.quill_visible(length, elapsed) and "▍" or " "
  local rest  = math.max(0, length - typed - 1)
  vim.api.nvim_buf_set_extmark(s.buf, ns, row - 1, 0, {
    virt_text = {
      { vim.fn.strcharpart(text, 0, typed), "SnacksDashboardDesc" },
      { quill, "EldenQuill" },
      { (" "):rep(rest), "SnacksDashboardNormal" },
    },
    virt_text_win_col = col,
    priority = 400,
  })
  s.quill_mask = { row = row - 1, from = col, to = col + length }
end

local function tick(s, elapsed)
  if not vim.api.nvim_buf_is_valid(s.buf) then return false end
  s.win = vim.fn.bufwinid(s.buf)
  if s.win == -1 then return false end

  local changedtick = vim.api.nvim_buf_get_changedtick(s.buf)
  if changedtick ~= s.changedtick then
    s.rows, s.changedtick = index_buffer(s.buf), changedtick
  end
  s.width = vim.api.nvim_win_get_width(s.win)

  local dt = elapsed - (s.last or elapsed)
  s.last = elapsed
  vim.api.nvim_buf_clear_namespace(s.buf, ns, 0, -1)
  draw_quill(s, elapsed)
  draw_shimmer(s, elapsed)
  draw_embers(s, dt)
end

function M.stop()
  if not session then return end
  session.loop:stop()
  if vim.api.nvim_buf_is_valid(session.buf) then vim.api.nvim_buf_clear_namespace(session.buf, ns, 0, -1) end
  session = nil
end

function M.start(buf)
  if session and session.buf == buf and session.loop:running() then return end
  M.stop()
  local s = { buf = buf, embers = {} }
  s.loop = motion.loop({ interval = FRAME_MS, on_tick = function(elapsed) return tick(s, elapsed) end })
  session = s
end

local function start_on_visible_dashboard()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == "snacks_dashboard" then return M.start(buf) end
  end
end

function M.setup()
  define_highlights()
  local group = vim.api.nvim_create_augroup("eldentree_hub", { clear = true })
  vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = define_highlights })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = { "SnacksDashboardOpened", "SnacksDashboardUpdatePost" },
    callback = function() vim.schedule(start_on_visible_dashboard) end,
  })
  vim.api.nvim_create_autocmd("User", { group = group, pattern = "SnacksDashboardClosed", callback = M.stop })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "EldentreeMotion",
    callback = function()
      if motion.enabled() then start_on_visible_dashboard() else M.stop() end
    end,
  })
end

return M
