-- Watches for a long idle in normal mode, then lays a dim veil over the editor with embers
-- drifting up through it. The key that wakes you is swallowed so it never edits anything.
local actions = require("core.rest.actions")
local embers = require("core.hub.actions")
local banner = require("core.banner.actions")
local motion = require("core.motion")
local color = require("core.motion.actions")

local M = {}

local ns = vim.api.nvim_create_namespace("eldentree_rest")
local last_input = vim.uv.now()
local scene

local function paint_groups(elapsed)
  local p = require("core.themes").palette()
  local veil = p.crust
  local veil_int = color.to_int(veil)
  local blend = banner.blend_for(actions.veil_alpha(elapsed))
  local text = actions.text_alpha(elapsed)
  local function text_group(name, fg, extra)
    vim.api.nvim_set_hl(
      0,
      name,
      vim.tbl_extend("force", {
        fg = color.mix(veil_int, color.to_int(fg), text),
        bg = veil,
        blend = blend,
      }, extra or {})
    )
  end
  vim.api.nvim_set_hl(0, "EldenRestVeil", { bg = veil, blend = blend })
  text_group("EldenRestTitle", p.yellow, { bold = true })
  text_group("EldenRestSub", p.subtext0, { italic = true })
  text_group("EldenRestHint", p.overlay1, { italic = true })
  for level = 1, embers.EMBER_LEVELS do
    local hue =
      color.mix(color.to_int(p.peach), color.to_int(p.yellow), level / embers.EMBER_LEVELS)
    vim.api.nvim_set_hl(0, "EldenRestEmber" .. level, {
      fg = color.mix(veil_int, hue, 0.3 + 0.7 * level / embers.EMBER_LEVELS),
      bg = veil,
      blend = blend,
    })
  end
end

-- typed lines grow letter by letter with a blinking key cursor, the rest are written in full
local function line_text(line, elapsed)
  if not line.typed then
    return line.text
  end
  local written, done = actions.typed(line.text, elapsed)
  local cursor = (not done or math.floor(elapsed / 530) % 2 == 0) and "▌" or " "
  return written .. cursor
end

local function draw(s, elapsed)
  if not vim.api.nvim_win_is_valid(s.win) then
    return false
  end
  paint_groups(elapsed)
  local dt = elapsed - (s.last or elapsed)
  s.last = elapsed

  vim.api.nvim_buf_clear_namespace(s.buf, ns, 0, -1)
  for _, line in ipairs(s.text) do
    vim.api.nvim_buf_set_extmark(s.buf, ns, line.row, 0, {
      virt_text = { { line_text(line, elapsed), line.group } },
      virt_text_win_col = line.col,
      priority = 200,
    })
  end
  if s.style == "typewriter" then
    return
  end

  local alive = {}
  for _, ember in ipairs(s.embers) do
    embers.step_ember(ember, dt)
    if embers.ember_alive(ember) then
      table.insert(alive, ember)
    end
  end
  while #alive < embers.ember_budget(s.width, s.height) * 1.5 and math.random() < 0.4 do
    table.insert(alive, embers.spawn_ember(math.random, s.width, s.height))
  end
  s.embers = alive

  for _, ember in ipairs(alive) do
    local row, col = math.floor(ember.y), math.floor(ember.x)
    if row >= 0 and row < s.height and col >= 0 and col < s.width and not s.text_rows[row] then
      local glyph, level = embers.ember_look(ember)
      vim.api.nvim_buf_set_extmark(s.buf, ns, row, 0, {
        virt_text = { { glyph, "EldenRestEmber" .. level } },
        virt_text_win_col = col,
        priority = 100,
      })
    end
  end
end

function M.wake()
  if not scene then
    return
  end
  scene.loop:stop()
  -- the rest sound can be a whole save room theme, it ends when you wake
  if scene.sound then
    pcall(scene.sound.kill, scene.sound, 15)
  end
  pcall(vim.api.nvim_win_close, scene.win, true)
  pcall(vim.api.nvim_buf_delete, scene.buf, { force = true })
  scene = nil
end

function M.rest()
  if scene then
    return
  end
  local width, height = vim.o.columns, vim.o.lines
  local s = { width = width, height = height, embers = {}, text_rows = {} }
  s.sound = require("core.sound").play("rest")
  s.style = require("core.franchise").mechanic("rest")
  s.text = actions.layout(width, height, require("core.themes").current().title, {
    style = s.style,
    ribbons = require("core.results").current().saves,
  })
  for _, line in ipairs(s.text) do
    s.text_rows[line.row] = true
  end

  paint_groups(0)
  s.buf = vim.api.nvim_create_buf(false, true)
  vim.bo[s.buf].bufhidden = "wipe"
  local blank = (" "):rep(width)
  local lines = {}
  for index = 1, height do
    lines[index] = blank
  end
  vim.api.nvim_buf_set_lines(s.buf, 0, -1, false, lines)

  s.win = vim.api.nvim_open_win(s.buf, false, {
    relative = "editor",
    row = 0,
    col = 0,
    width = width,
    height = height,
    style = "minimal",
    border = "none",
    focusable = false,
    zindex = 200,
    noautocmd = true,
  })
  vim.wo[s.win].winblend = 1
  vim.wo[s.win].winhighlight = "Normal:EldenRestVeil"

  scene = s
  s.loop = motion.loop({
    interval = 50,
    on_tick = function(elapsed)
      return draw(s, elapsed)
    end,
  })
end

function M.setup()
  vim.on_key(function()
    last_input = vim.uv.now()
    if scene then
      vim.schedule(M.wake)
      return ""
    end
  end, ns)

  -- checking every few seconds is plenty when the threshold is measured in minutes
  M.watch = motion.loop({
    interval = 5000,
    on_tick = function()
      local ready = actions.should_rest({
        idle = vim.uv.now() - last_input,
        after = vim.g.eldentree_rest_after,
        mode = vim.api.nvim_get_mode().mode,
        enabled = motion.enabled() and vim.g.eldentree_rest ~= false,
        resting = scene ~= nil,
      })
      if ready then
        M.rest()
      end
    end,
  })

  vim.api.nvim_create_autocmd("VimResized", {
    group = vim.api.nvim_create_augroup("eldentree_rest", { clear = true }),
    callback = M.wake,
  })
  vim.api.nvim_create_user_command(
    "Rest",
    M.rest,
    { desc = "Rest at a Site of Grace or Safe Room" }
  )
end

return M
