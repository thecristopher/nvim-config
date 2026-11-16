-- Every save sends a glint over the statusline: the mode badge lights up first, then the branch, then
-- the middle, mirrored on the right so the light runs from both ends to the center and fades. Rides
-- core/motion's clock, stills with it, and always ends on the theme's exact colors.
local actions = require("core.chrome.actions.glint")

local M = {}

local running
local running_mode

local function theme()
  return require("core.themes.actions").lualine_theme(require("core.themes").palette())
end

-- every group of the mode the glint repaints, with which of its colors follow which section
local function collect(mode)
  local entries = {}
  for name in pairs(vim.api.nvim_get_hl(0, {})) do
    local left, right = actions.transitional_sections(name, mode)
    local sides = left and { fg = left, bg = right } or nil
    if not sides and actions.section_of(name, mode) then
      sides = { bg = actions.section_of(name, mode) }
    end
    if sides then
      table.insert(entries, {
        name = name,
        attrs = vim.api.nvim_get_hl(0, { name = name, link = false }),
        sides = sides,
      })
    end
  end
  return entries
end

local function paint(entries, colors, lights, elapsed)
  for _, entry in ipairs(entries) do
    local attrs = vim.deepcopy(entry.attrs)
    for side, section in pairs(entry.sides) do
      attrs[side] =
        actions.glinted(colors[section].bg, lights[section], actions.strength(elapsed, section))
    end
    vim.api.nvim_set_hl(0, entry.name, attrs)
  end
end

local function rest(entries, colors)
  paint(entries, colors, {}, 0)
end

--- Stops a glint halfway, putting the groups back on their resting colors.
function M.cancel()
  if running and running:running() then
    running:stop()
    local colors = theme()[running_mode]
    if colors then
      rest(collect(running_mode), colors)
    end
  end
  running, running_mode = nil, nil
end

--- Sends the glint over the statusline of the mode in use.
function M.play()
  local motion = require("core.motion")
  if not motion.enabled() then
    return
  end
  M.cancel()
  local mode = require("core.chrome.actions").mode_name(vim.api.nvim_get_mode().mode)
  local colors = theme()[mode]
  local entries = collect(mode)
  if not colors or #entries == 0 then
    return
  end
  local lights = actions.lights(require("core.themes").palette())
  running_mode = mode
  running = motion.tween({
    duration = actions.TOTAL_MS,
    easing = "linear",
    on_frame = function(_, raw)
      paint(entries, colors, lights, raw * actions.TOTAL_MS)
    end,
    on_done = function()
      rest(entries, colors)
      running, running_mode = nil, nil
    end,
  })
end

local function saved_a_file(args)
  return vim.bo[args.buf].buftype == "" and vim.api.nvim_buf_get_name(args.buf) ~= ""
end

function M.setup(group)
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    callback = function(args)
      -- :w fires this while still in command mode, the glint plays once back in the mode it saved from
      if saved_a_file(args) then
        vim.schedule(M.play)
      end
    end,
  })
  vim.api.nvim_create_autocmd("ModeChanged", {
    group = group,
    callback = function()
      local now = require("core.chrome.actions").mode_name(vim.v.event.new_mode)
      if running_mode and now ~= running_mode then
        M.cancel()
      end
    end,
  })
  -- lualine paints its groups anew on ColorScheme, so the glint just lets go of them
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = group,
    callback = function()
      if running then
        running:stop()
      end
      running, running_mode = nil, nil
    end,
  })
end

return M
