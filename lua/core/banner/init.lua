-- Full width banners for the moments that deserve one: commits, PRs, deaths and new regions.
-- The text sits on a blended float, so every cell gets its own transparency and the band melts into the code.
local actions = require("core.banner.actions")
local motion = require("core.motion")
local color = require("core.motion.actions")

local M = {}

local ns = vim.api.nvim_create_namespace("eldentree_banner")
local current

local function palette()
  return require("core.themes").palette()
end

local function close(state)
  if not state then
    return
  end
  if state.tween then
    state.tween:stop()
  end
  pcall(vim.api.nvim_win_close, state.win, true)
  pcall(vim.api.nvim_buf_delete, state.buf, { force = true })
end

local function split_chars(text)
  return vim.fn.split(text, "\\zs")
end

-- the shadow every cell starts on, already quantized into the band's levels
local function ground(kind, geometry, width)
  local rows = {}
  for row = 0, geometry.height - 1 do
    local cells = {}
    for col = 0, width - 1 do
      local alpha = actions.ground_alpha(kind, row, col, width, geometry.height)
      cells[col + 1] = { " ", "EldenBand" .. actions.quantize(alpha, actions.BAND_LEVELS) }
    end
    rows[row + 1] = cells
  end
  return rows
end

-- writes text into a row of cells from a display column, one cell per character
local function put_text(rows, row, col, text, group)
  for offset, char in ipairs(split_chars(text)) do
    if rows[row + 1] and rows[row + 1][col + offset] then
      rows[row + 1][col + offset] = { char, group }
    end
  end
end

local function put_letters(rows, geometry, text, width)
  local start = actions.center_col(width, #text)
  local letters = {}
  for offset, char in ipairs(split_chars(text)) do
    if char ~= " " and start + offset <= width then
      table.insert(letters, start + offset - 1)
      rows[geometry.text + 1][start + offset] = { char, "EldenBannerL" .. #letters }
    end
  end
  return letters
end

local function put_drips(rows, geometry, letters)
  for _, drip in ipairs(actions.drips(letters)) do
    for depth = 1, drip.length do
      local glyph = depth == drip.length and "▾" or "│"
      rows[geometry.text + depth + 1][drip.col + 1] = { glyph, "EldenBannerDrip" .. depth }
    end
  end
end

local function put_rule(rows, geometry, text, width)
  local length = math.min(width, #text + 16)
  local rule_start = actions.center_col(width, length)
  for index = 1, length do
    local level = actions.quantize(actions.rule_alpha(index, length), actions.BAND_LEVELS)
    rows[geometry.rule + 1][rule_start + index] = { "─", "EldenBannerRule" .. level }
  end
end

local SLATE_GROUPS = {
  open = "EldenBannerOpen",
  hinge = "EldenBannerOpen",
  shut = "EldenBannerShut",
  slate = "EldenBannerSlate",
}

-- every cell in the float, as { char, group } rows
local function layout(kind, subtitle, width, geometry)
  local rows = ground(kind, geometry, width)
  local text = actions.spaced(kind.text)
  local letters = put_letters(rows, geometry, text, width)
  if kind.drip then
    put_drips(rows, geometry, letters)
  end
  if kind.rule then
    put_rule(rows, geometry, text, width)
  end
  if geometry.slate then
    for _, piece in ipairs(actions.slate(#text, width)) do
      put_text(rows, geometry.slate + piece.row, piece.col, piece.text, SLATE_GROUPS[piece.part])
    end
  end
  if subtitle and subtitle ~= "" then
    local chars = vim.fn.strcharpart(subtitle, 0, width - 8)
    put_text(
      rows,
      geometry.sub,
      actions.center_col(width, vim.fn.strchars(chars)),
      chars,
      "EldenBannerSub"
    )
  end
  return rows, letters
end

-- writes the cells once, the animation only ever touches highlight definitions afterwards
local function paint(buf, rows)
  local lines = {}
  for index, cells in ipairs(rows) do
    lines[index] = table.concat(vim.tbl_map(function(cell)
      return cell[1]
    end, cells))
  end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  for index, cells in ipairs(rows) do
    local byte, run_start, run_group = 0, 0, nil
    local function flush()
      if run_group and byte > run_start then
        vim.api.nvim_buf_set_extmark(
          buf,
          ns,
          index - 1,
          run_start,
          { end_col = byte, hl_group = run_group }
        )
      end
    end
    for _, cell in ipairs(cells) do
      if cell[2] ~= run_group then
        flush()
        run_start, run_group = byte, cell[2]
      end
      byte = byte + #cell[1]
    end
    flush()
  end
end

local function update_groups(state, elapsed)
  local p = palette()
  local kind = state.kind
  -- a blackout sinks the whole screen to true black, the band rests on the region's darkest tone
  local band = kind.look == "blackout" and "#000000" or p.crust
  local target = color.to_int(p[kind.color] or p.yellow)
  local band_int = color.to_int(band)
  local opacity = actions.envelope(elapsed, kind)
  local geometry = state.geometry
  local text_alpha = actions.ground_alpha(
    kind,
    geometry.text,
    math.floor(state.width / 2),
    state.width,
    geometry.height
  )
  local text_blend = actions.blend_for(text_alpha * kind.band * opacity)

  for level = 0, actions.BAND_LEVELS do
    local alpha = level / actions.BAND_LEVELS * kind.band * opacity
    vim.api.nvim_set_hl(0, "EldenBand" .. level, { bg = band, blend = actions.blend_for(alpha) })
    vim.api.nvim_set_hl(0, "EldenBannerRule" .. level, {
      fg = color.mix(band_int, target, level / actions.BAND_LEVELS * opacity),
      bg = band,
      blend = text_blend,
    })
  end

  for index = 1, #state.letters do
    vim.api.nvim_set_hl(0, "EldenBannerL" .. index, {
      fg = color.mix(band_int, target, actions.letter_alpha(index, elapsed, kind)),
      bg = band,
      blend = text_blend,
      bold = true,
    })
  end

  for depth = 1, kind.drip and actions.DRIP_DEPTH or 0 do
    vim.api.nvim_set_hl(0, "EldenBannerDrip" .. depth, {
      fg = color.mix(band_int, target, actions.drip_alpha(depth, elapsed, kind)),
      bg = band,
      blend = text_blend,
    })
  end

  if geometry.slate then
    local open, shut = actions.clapper_alpha(elapsed, kind)
    local chalk = color.to_int(p.text)
    vim.api.nvim_set_hl(
      0,
      "EldenBannerOpen",
      { fg = color.mix(band_int, chalk, open), bg = band, blend = text_blend }
    )
    vim.api.nvim_set_hl(
      0,
      "EldenBannerShut",
      { fg = color.mix(band_int, chalk, shut), bg = band, blend = text_blend }
    )
    vim.api.nvim_set_hl(0, "EldenBannerSlate", {
      fg = color.mix(band_int, chalk, opacity * 0.85),
      bg = band,
      blend = text_blend,
    })
  end

  vim.api.nvim_set_hl(0, "EldenBannerSub", {
    fg = color.mix(band_int, color.to_int(p.subtext0), opacity),
    bg = band,
    blend = text_blend,
    italic = true,
  })
end

-- the code crumbles behind YOU DIED and comes back as the banner fades
local function crumble(duration)
  local ok = pcall(require("cellular-automaton").start_animation, "make_it_rain")
  -- the rain window takes focus, so this is the one to close later
  local rain = vim.api.nvim_get_current_win()
  if not ok then
    return
  end
  vim.defer_fn(function()
    if vim.api.nvim_win_is_valid(rain) then
      require("cellular-automaton.manager").clean()
    end
  end, duration)
end

-- shows a banner by kind name ("felled", "great", "died", "grace", "cleansed", "region"),
-- opts.sound = false when another sound already speaks for it, opts.merchant = false pays the
-- runes without the merchant's visit
function M.show(name, opts)
  opts = opts or {}
  local kind = actions.kind(name, opts.kind)
  if not kind or kind.text == "" then
    return
  end
  -- runes change hands even when the banner itself stays hidden
  if opts.reward ~= false then
    require("core.runes").after_banner(name, { merchant = opts.merchant })
  end
  if not motion.enabled() or vim.g.eldentree_banners == false then
    return
  end
  if opts.sound ~= false then
    require("core.sound").play(name)
  end
  require("core.pixel").pop(name)
  if actions.rains(name, vim.bo.buftype, vim.g.eldentree_rain) then
    crumble(kind.duration)
  end

  close(current)
  local width = vim.o.columns
  local geometry = actions.geometry(kind, vim.o.lines - vim.o.cmdheight - 1)
  local rows, letters = layout(kind, opts.subtitle, width, geometry)
  local state = { kind = kind, width = width, letters = letters, geometry = geometry }
  update_groups(state, 0)

  state.buf = vim.api.nvim_create_buf(false, true)
  vim.bo[state.buf].bufhidden = "wipe"
  paint(state.buf, rows)

  state.win = vim.api.nvim_open_win(state.buf, false, {
    relative = "editor",
    row = kind.look == "blackout" and 0
      or math.max(0, math.floor((vim.o.lines - geometry.height) * 0.4)),
    col = 0,
    width = width,
    height = geometry.height,
    style = "minimal",
    border = "none",
    focusable = false,
    zindex = 250,
    noautocmd = true,
  })
  -- any winblend switches on per cell blending, the groups then choose their own amount
  vim.wo[state.win].winblend = 1
  vim.wo[state.win].winhighlight = "Normal:EldenBand0"

  current = state
  state.tween = motion.tween({
    duration = kind.duration,
    easing = "linear",
    frame_ms = 33,
    on_frame = function(_, raw)
      update_groups(state, raw * kind.duration)
    end,
    on_done = function()
      close(state)
      if current == state then
        current = nil
      end
    end,
  })
end

--- Tells whether a banner is on screen, so quieter ones can wait their turn.
---@return boolean
function M.busy()
  return current ~= nil
end

function M.region(region)
  M.show("region", { kind = { text = region.title }, subtitle = region.tagline, reward = false })
end

-- remembers how long each buffer has been stuck with errors, and celebrates when they finally clear
local function watch_diagnostics()
  local fights, last_shown = {}, nil
  vim.api.nvim_create_autocmd("DiagnosticChanged", {
    group = vim.api.nvim_create_augroup("eldentree_banner_diagnostics", { clear = true }),
    callback = function(ev)
      if not vim.api.nvim_buf_is_valid(ev.buf) or vim.bo[ev.buf].buftype ~= "" then
        return
      end
      local errors = #vim.diagnostic.get(ev.buf, { severity = vim.diagnostic.severity.ERROR })
      local now = vim.uv.now()
      if errors > 0 then
        fights[ev.buf] = fights[ev.buf] or now
        return
      end
      -- a boss fight in this buffer ends with its own banner
      if require("core.boss").engaged(ev.buf) then
        fights[ev.buf] = nil
        return
      end
      if
        actions.should_cleanse({
          errors = errors,
          errors_since = fights[ev.buf],
          now = now,
          last_shown = last_shown,
        })
      then
        last_shown = now
        M.show(
          "cleansed",
          { subtitle = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(ev.buf), ":t") }
        )
      end
      fights[ev.buf] = nil
    end,
  })
end

function M.setup()
  watch_diagnostics()
  vim.api.nvim_create_user_command("Banner", function(cmd)
    -- a rehearsal, so no runes are won or lost
    local name = cmd.args ~= "" and cmd.args or "felled"
    local salute = require("core.franchise").current().words.salute
    M.show(name, { subtitle = actions.preview_subtitle(name, salute), reward = false })
  end, {
    nargs = "?",
    complete = function()
      return vim.tbl_keys(actions.KINDS)
    end,
    desc = "Show an Eldentree banner",
  })
end

return M
