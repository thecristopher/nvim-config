-- Power Mode: pixel-art combo counter + particle explosions + screen shake
-- Toggle: <leader>uK

local M   = {}
local uv  = vim.uv
local api = vim.api

-- ─── Pixel art digit bitmaps (5 rows × 3 cols, █ = filled, space = empty) ──
local PIXEL = {
  ["0"] = { "███", "█ █", "█ █", "█ █", "███" },
  ["1"] = { " █ ", " █ ", " █ ", " █ ", "███" },
  ["2"] = { "███", "  █", "███", "█  ", "███" },
  ["3"] = { "███", "  █", "███", "  █", "███" },
  ["4"] = { "█ █", "█ █", "███", "  █", "  █" },
  ["5"] = { "███", "█  ", "███", "  █", "███" },
  ["6"] = { "███", "█  ", "███", "█ █", "███" },
  ["7"] = { "███", "  █", "  █", "  █", "  █" },
  ["8"] = { "███", "█ █", "███", "█ █", "███" },
  ["9"] = { "███", "█ █", "███", "  █", "███" },
  ["x"] = { "   ", "█ █", " █ ", "█ █", "   " },
}

-- ─── Particle symbols by intensity ──────────────────────────────────────────
local SYMS = {
  low  = { "·", "∗", "⁕", "✦", "✧", "⬝", "∙" },
  mid  = { "★", "✶", "✸", "◈", "⬟", "⬡", "✹" },
  high = { "🔥", "⚡", "💥", "✨", "💫", "🌟", "☄" },
}

local PARTICLE_HLS = {
  low  = { "PMSpark1", "PMSpark2", "PMSpark3" },
  mid  = { "PMFlame1", "PMFlame2", "PMFlame3" },
  high = { "PMMega1",  "PMMega2",  "PMMega3"  },
}

-- ─── SF combo database ───────────────────────────────────────────────────────
local COMBOS = {
  { tail={"d","i","w"}, name="💥 SONIC BOOM!",       hi="SFComboFire"  },
  { tail={"c","i","w"}, name="🌊 YOGA FLAME!",        hi="SFComboIce"   },
  { tail={"d","a","w"}, name="🐯 TIGER SHOT!",        hi="SFComboGold"  },
  { tail={".",".","."}, name="⚔  TRIPLE COMBO!!",     hi="SFComboPurp"  },
  { tail={"d","d"},     name="🔥 HADOUKEN!",          hi="SFComboFire"  },
  { tail={"y","y"},     name="🌀 TATSUMAKI!",         hi="SFComboPurp"  },
  { tail={"c","c"},     name="🌊 YOGA FLAME!",        hi="SFComboIce"   },
  { tail={"g","g"},     name="⚡ SHORYUKEN!",         hi="SFComboElec"  },
  { tail={"<","<"},     name="◀  TIGER UPPER!",       hi="SFComboGold"  },
  { tail={">",">"},     name="▶  TIGER KNEE!",        hi="SFComboGold"  },
  { tail={"Z","Z"},     name="✅ FLAWLESS VICTORY!",  hi="SFComboGreen" },
  { tail={"Z","Q"},     name="💨 COWARD!",            hi="SFComboDim"   },
}

-- ─── Config ──────────────────────────────────────────────────────────────────
local CFG = {
  max_particles = 35,
  frame_ms      = 33,
  ttl           = 16,
  gravity       = 0.20,
  air_resist    = 0.90,
  win_w         = 22,
  win_h         = 6,   -- 5 pixel rows + 1 SF name row
  combo_decay   = 2000,
  hud_fade      = 3200,
  flash_ms      = 1900,
  shake_frames  = 8,
  shake_ms      = 30,
}

-- ─── State ───────────────────────────────────────────────────────────────────
local S = {
  enabled      = false,
  particles    = {},
  buf_pool     = {},
  anim_timer   = nil,
  hud_timer    = nil,
  cdecay_timer = nil,
  flash_timer  = nil,
  shake_timer  = nil,
  key_hist     = {},
  combo        = 0,
  sf_combo     = nil,
  hud_buf      = nil,
  hud_win      = nil,
  ns           = api.nvim_create_namespace("sfcombo"),
}

-- ─── Highlights ──────────────────────────────────────────────────────────────
local BG = "#120F0C"

function M.setup_hls()
  -- HUD chrome
  api.nvim_set_hl(0, "SFComboBg",     { bg = BG })
  api.nvim_set_hl(0, "SFComboBorder", { fg = "#6A4A28", bg = BG })
  api.nvim_set_hl(0, "SFComboTitle",  { fg = "#C9A84C", bg = BG, bold = true })
  -- SF combo name colors
  api.nvim_set_hl(0, "SFComboFire",   { fg = "#FF6030", bg = BG, bold = true })
  api.nvim_set_hl(0, "SFComboElec",   { fg = "#F8E040", bg = BG, bold = true })
  api.nvim_set_hl(0, "SFComboIce",    { fg = "#60C8FF", bg = BG, bold = true })
  api.nvim_set_hl(0, "SFComboPurp",   { fg = "#D080FF", bg = BG, bold = true })
  api.nvim_set_hl(0, "SFComboGold",   { fg = "#FFC840", bg = BG, bold = true })
  api.nvim_set_hl(0, "SFComboGreen",  { fg = "#60E060", bg = BG, bold = true })
  api.nvim_set_hl(0, "SFComboDim",    { fg = "#706050", bg = BG, italic = true })
  -- Pixel digit gradient: low=gold, mid=fire (tip→base), high=plasma (tip→base)
  api.nvim_set_hl(0, "PMDigLow",  { fg = "#FFD060",              bg = BG })
  api.nvim_set_hl(0, "PMDigMidT", { fg = "#FFF080", bold = true, bg = BG })
  api.nvim_set_hl(0, "PMDigMidM", { fg = "#FF8030", bold = true, bg = BG })
  api.nvim_set_hl(0, "PMDigMidB", { fg = "#FF3010", bold = true, bg = BG })
  api.nvim_set_hl(0, "PMDigHiT",  { fg = "#FF80FF", bold = true, bg = BG })
  api.nvim_set_hl(0, "PMDigHiM",  { fg = "#FF2080", bold = true, bg = BG })
  api.nvim_set_hl(0, "PMDigHiB",  { fg = "#8040FF", bold = true, bg = BG })
  -- Particle highlights
  api.nvim_set_hl(0, "PMSpark1", { fg = "#FFE8A0" })
  api.nvim_set_hl(0, "PMSpark2", { fg = "#FFD060" })
  api.nvim_set_hl(0, "PMSpark3", { fg = "#FFF0C0" })
  api.nvim_set_hl(0, "PMFlame1", { fg = "#FF8030", bold = true })
  api.nvim_set_hl(0, "PMFlame2", { fg = "#FF4810", bold = true })
  api.nvim_set_hl(0, "PMFlame3", { fg = "#FFA040", bold = true })
  api.nvim_set_hl(0, "PMMega1",  { fg = "#FF2080", bold = true })
  api.nvim_set_hl(0, "PMMega2",  { fg = "#8040FF", bold = true })
  api.nvim_set_hl(0, "PMMega3",  { fg = "#00FFAA", bold = true })
end

-- ─── Helpers ─────────────────────────────────────────────────────────────────
local function kill(t)
  if t then pcall(function() t:stop(); t:close() end) end
end

local function center_line(s, w)
  local sw    = vim.fn.strdisplaywidth(s)
  local left  = math.max(0, math.floor((w - sw) / 2))
  local right = math.max(0, w - left - sw)
  return string.rep(" ", left) .. s .. string.rep(" ", right)
end

-- ─── Buffer pool ─────────────────────────────────────────────────────────────
local function get_buf(sym)
  local b = table.remove(S.buf_pool)
  if not b or not api.nvim_buf_is_valid(b) then
    b = api.nvim_create_buf(false, true)
    vim.bo[b].buftype   = "nofile"
    vim.bo[b].bufhidden = "hide"
    vim.bo[b].swapfile  = false
  end
  api.nvim_buf_set_lines(b, 0, -1, false, { sym })
  return b
end

local function free_buf(b)
  if #S.buf_pool < 50 and api.nvim_buf_is_valid(b) then
    api.nvim_buf_set_lines(b, 0, -1, false, { " " })
    table.insert(S.buf_pool, b)
  else
    pcall(api.nvim_buf_delete, b, { force = true })
  end
end

-- ─── Screen shake ────────────────────────────────────────────────────────────
local function screen_shake(strength)
  if S.shake_timer then return end
  local saved = vim.fn.winsaveview()
  local n = 0
  S.shake_timer = uv.new_timer()
  S.shake_timer:start(0, CFG.shake_ms, vim.schedule_wrap(function()
    n = n + 1
    if n > CFG.shake_frames then
      kill(S.shake_timer); S.shake_timer = nil
      pcall(vim.fn.winrestview, saved)
      return
    end
    local v = vim.fn.winsaveview()
    v.topline = math.max(1, v.topline + (n % 2 == 0 and strength or -strength))
    pcall(vim.fn.winrestview, v)
  end))
end

-- ─── Screen flash ────────────────────────────────────────────────────────────
local function screen_flash(color)
  local fbuf = api.nvim_create_buf(false, true)
  vim.bo[fbuf].buftype   = "nofile"
  vim.bo[fbuf].bufhidden = "wipe"
  local blank = string.rep(" ", vim.o.columns)
  local rows  = {}
  for _ = 1, vim.o.lines do rows[#rows + 1] = blank end
  api.nvim_buf_set_lines(fbuf, 0, -1, false, rows)
  local hl = "PMFlash_" .. color:sub(2)
  api.nvim_set_hl(0, hl, { bg = color })
  local ok, fw = pcall(api.nvim_open_win, fbuf, false, {
    relative = "editor", row = 0, col = 0,
    width = vim.o.columns, height = vim.o.lines,
    style = "minimal", focusable = false, noautocmd = true, zindex = 500,
  })
  if not ok then pcall(api.nvim_buf_delete, fbuf, { force = true }); return end
  vim.wo[fw].winhl    = "Normal:" .. hl
  vim.wo[fw].winblend = 72
  local blend = 72
  local ft = uv.new_timer()
  ft:start(0, 16, vim.schedule_wrap(function()
    blend = blend + 4
    if blend >= 100 then
      ft:stop(); ft:close()
      pcall(api.nvim_win_close, fw, true)
      return
    end
    pcall(function() vim.wo[fw].winblend = blend end)
  end))
end

-- ─── Particle animation step ─────────────────────────────────────────────────
local function step_particles()
  local alive = {}
  local cols  = vim.o.columns
  local lines = vim.o.lines
  for _, p in ipairs(S.particles) do
    p.ttl = p.ttl - 1
    if p.ttl <= 0 then
      pcall(api.nvim_win_close, p.win, true)
      free_buf(p.buf)
    else
      p.row = p.row + p.vr
      p.col = p.col + p.vc
      p.vr  = p.vr  + CFG.gravity
      p.vc  = p.vc  * CFG.air_resist

      local r = math.floor(p.row)
      local c = math.floor(p.col)

      if r < 0 or r >= lines - 1 or c < 0 or c >= cols - 2 then
        pcall(api.nvim_win_close, p.win, true)
        free_buf(p.buf)
      else
        local blend = math.floor((1 - p.ttl / p.max_ttl) * 78)
        pcall(api.nvim_win_set_config, p.win, { relative = "editor", row = r, col = c })
        pcall(function() vim.wo[p.win].winblend = blend end)
        alive[#alive + 1] = p
      end
    end
  end
  S.particles = alive
  if #S.particles == 0 then
    kill(S.anim_timer); S.anim_timer = nil
  end
end

local function start_anim()
  if S.anim_timer then return end
  S.anim_timer = uv.new_timer()
  S.anim_timer:start(CFG.frame_ms, CFG.frame_ms, vim.schedule_wrap(step_particles))
end

-- ─── Explosion ───────────────────────────────────────────────────────────────
local function explode(n_override)
  local sp = vim.fn.screenpos(0, vim.fn.line("."), vim.fn.col("."))
  if sp.row == 0 then return end

  local cr = sp.row - 1
  local cc = sp.col - 1

  local level = S.combo >= 60 and "high" or S.combo >= 20 and "mid" or "low"
  local syms  = SYMS[level]
  local hls   = PARTICLE_HLS[level]
  local n     = n_override or (level == "high" and 10 or level == "mid" and 6 or 4)
  n = math.min(n, CFG.max_particles - #S.particles)
  if n <= 0 then return end

  local cols  = vim.o.columns
  local lines = vim.o.lines

  for _ = 1, n do
    local sym = syms[math.random(#syms)]
    local hl  = hls[math.random(#hls)]
    local buf = get_buf(sym)
    local angle = math.random() * math.pi * 2
    local spd   = 1.4 + math.random() * 2.2
    local vr    = math.sin(angle) * spd * 0.65 - 0.4
    local vc    = math.cos(angle) * spd * 1.4
    local r = math.max(0, math.min(lines - 2, cr))
    local c = math.max(0, math.min(cols  - 3, cc))
    local ok, win = pcall(api.nvim_open_win, buf, false, {
      relative = "editor", row = r, col = c,
      width = 2, height = 1,
      style = "minimal", focusable = false, noautocmd = true,
      zindex = 150 + math.random(40),
    })
    if ok then
      pcall(function()
        vim.wo[win].winhl    = "Normal:" .. hl
        vim.wo[win].winblend = 0
        vim.wo[win].wrap     = false
      end)
      S.particles[#S.particles + 1] = {
        win = win, buf = buf,
        row = cr + 0.0, col = cc + 0.0,
        vr = vr, vc = vc,
        ttl = CFG.ttl, max_ttl = CFG.ttl,
      }
    else
      free_buf(buf)
    end
  end
  start_anim()
end

-- ─── Pixel art renderer ──────────────────────────────────────────────────────
local function pixel_number(n)
  local str  = tostring(n) .. "x"
  local rows = { "", "", "", "", "" }
  for i = 1, #str do
    local ch = str:sub(i, i)
    local bm = PIXEL[ch]
    if bm then
      local sep = i > 1 and " " or ""
      for r = 1, 5 do
        rows[r] = rows[r] .. sep .. bm[r]
      end
    end
  end
  return rows
end

-- ─── HUD ─────────────────────────────────────────────────────────────────────
local function hud_open()
  if S.hud_win and api.nvim_win_is_valid(S.hud_win) then return end
  if not S.hud_buf or not api.nvim_buf_is_valid(S.hud_buf) then
    S.hud_buf = api.nvim_create_buf(false, true)
    vim.bo[S.hud_buf].buftype   = "nofile"
    vim.bo[S.hud_buf].bufhidden = "hide"
    local blank = string.rep(" ", CFG.win_w)
    api.nvim_buf_set_lines(S.hud_buf, 0, -1, false,
      { blank, blank, blank, blank, blank, blank })
  end
  S.hud_win = api.nvim_open_win(S.hud_buf, false, {
    relative  = "editor", anchor = "NE",
    row = 1,  col = vim.o.columns - 2,
    width     = CFG.win_w, height = CFG.win_h,
    style     = "minimal",
    border    = { "╔", "═", "╗", "║", "╝", "═", "╚", "║" },
    title     = " COMBO ",
    title_pos = "center",
    focusable = false, noautocmd = true, zindex = 60,
  })
  vim.wo[S.hud_win].winhl = "Normal:SFComboBg,FloatBorder:SFComboBorder,FloatTitle:SFComboTitle"
  vim.wo[S.hud_win].wrap  = false
end

local function hud_close()
  if S.hud_win and api.nvim_win_is_valid(S.hud_win) then
    api.nvim_win_close(S.hud_win, true); S.hud_win = nil
  end
end

local function hud_render()
  if not S.hud_buf or not api.nvim_buf_is_valid(S.hud_buf) then return end

  local w    = CFG.win_w
  local pix  = pixel_number(S.combo)
  local lines = {}

  -- 5 pixel art rows, centered
  for _, row in ipairs(pix) do
    lines[#lines + 1] = center_line(row, w)
  end

  -- Row 6: SF combo move name, or blank
  local sf_hl
  if S.sf_combo then
    lines[#lines + 1] = center_line(S.sf_combo.name, w)
    sf_hl = S.sf_combo.hi
  else
    lines[#lines + 1] = string.rep(" ", w)
  end

  api.nvim_buf_set_lines(S.hud_buf, 0, -1, false, lines)
  api.nvim_buf_clear_namespace(S.hud_buf, S.ns, 0, -1)

  -- Per-row gradient on the 5 digit rows (fire/plasma effect)
  local row_hls
  if S.combo >= 60 then
    row_hls = { "PMDigHiT", "PMDigHiT", "PMDigHiM", "PMDigHiB", "PMDigHiB" }
  elseif S.combo >= 20 then
    row_hls = { "PMDigMidT", "PMDigMidT", "PMDigMidM", "PMDigMidB", "PMDigMidB" }
  else
    row_hls = { "PMDigLow", "PMDigLow", "PMDigLow", "PMDigLow", "PMDigLow" }
  end
  for r = 0, 4 do
    api.nvim_buf_add_highlight(S.hud_buf, S.ns, row_hls[r + 1], r, 0, -1)
  end
  if sf_hl then
    api.nvim_buf_add_highlight(S.hud_buf, S.ns, sf_hl, 5, 0, -1)
  end
end

-- ─── SF combo detection ──────────────────────────────────────────────────────
local function check_sf()
  for _, c in ipairs(COMBOS) do
    local n = #c.tail
    if #S.key_hist >= n then
      local ok = true
      for i, k in ipairs(c.tail) do
        if S.key_hist[#S.key_hist - n + i] ~= k then ok = false; break end
      end
      if ok then return c end
    end
  end
end

-- ─── Key handler ─────────────────────────────────────────────────────────────
local function on_key(key)
  if key == "" then return end
  if key:byte(1) == 0x80 then return end
  if key:byte(1) == 0x1b and #key > 1 then return end

  S.key_hist[#S.key_hist + 1] = key
  if #S.key_hist > 16 then table.remove(S.key_hist, 1) end

  local prev_combo = S.combo
  S.combo = S.combo + 1

  kill(S.cdecay_timer)
  S.cdecay_timer = uv.new_timer()
  S.cdecay_timer:start(CFG.combo_decay, 0, vim.schedule_wrap(function()
    kill(S.cdecay_timer); S.cdecay_timer = nil
    S.combo = 0
    hud_render()
  end))

  local sf = check_sf()
  if sf and sf ~= S.sf_combo then
    S.sf_combo = sf
    kill(S.flash_timer)
    S.flash_timer = uv.new_timer()
    S.flash_timer:start(CFG.flash_ms, 0, vim.schedule_wrap(function()
      kill(S.flash_timer); S.flash_timer = nil
      S.sf_combo = nil
      hud_render()
    end))
  end

  vim.schedule(function()
    explode(sf and 16 or nil)

    if sf then
      screen_shake(2)
      screen_flash("#FF4000")
    elseif S.combo ~= prev_combo and S.combo % 50 == 0 then
      screen_shake(1)
      if S.combo >= 100 then screen_flash("#8000FF") end
    end

    hud_open()
    hud_render()

    kill(S.hud_timer)
    S.hud_timer = uv.new_timer()
    S.hud_timer:start(CFG.hud_fade, 0, vim.schedule_wrap(function()
      kill(S.hud_timer); S.hud_timer = nil
      hud_close()
    end))
  end)
end

-- ─── Public API ──────────────────────────────────────────────────────────────
M.enabled = false

function M.enable()
  if M.enabled then return end
  M.enabled = true
  M.setup_hls()
  vim.on_key(on_key, S.ns)
  vim.notify("ROUND 1 — FIGHT! 🥊", vim.log.levels.INFO, { title = "Power Mode" })
end

function M.disable()
  if not M.enabled then return end
  M.enabled = false
  vim.on_key(nil, S.ns)
  for _, t in ipairs({ S.anim_timer, S.hud_timer, S.cdecay_timer,
                       S.flash_timer, S.shake_timer }) do kill(t) end
  S.anim_timer = nil; S.hud_timer = nil; S.cdecay_timer = nil
  S.flash_timer = nil; S.shake_timer = nil
  for _, p in ipairs(S.particles) do
    pcall(api.nvim_win_close, p.win, true)
    free_buf(p.buf)
  end
  S.particles = {}; S.key_hist = {}; S.combo = 0; S.sf_combo = nil
  hud_close()
  vim.notify("Power Mode: OFF", vim.log.levels.INFO, { title = "Power Mode" })
end

function M.toggle()
  if M.enabled then M.disable() else M.enable() end
end

vim.api.nvim_create_autocmd("VimResized", {
  group    = vim.api.nvim_create_augroup("SFComboResize", { clear = true }),
  callback = function()
    if S.hud_win and api.nvim_win_is_valid(S.hud_win) then
      api.nvim_win_set_config(S.hud_win, {
        relative = "editor", anchor = "NE",
        row = 1, col = vim.o.columns - 2,
      })
    end
  end,
})

vim.api.nvim_create_autocmd("ColorScheme", {
  group    = vim.api.nvim_create_augroup("SFComboColors", { clear = true }),
  callback = M.setup_hls,
})

return M
