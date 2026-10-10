-- Region switcher: remembers your region, recolors catppuccin, and lets you
-- browse regions live with <leader>ut. Everything else follows the ColorScheme event.
local actions = require("core.themes.actions")
local motion  = require("core.motion")
local blend   = require("core.motion.actions")

local M = {}

local state_file = vim.fn.stdpath("state") .. "/eldentree_region"

local function read_saved()
  local ok, lines = pcall(vim.fn.readfile, state_file, "", 1)
  return ok and lines[1] or nil
end

local function save(name)
  pcall(vim.fn.writefile, { name }, state_file)
end

function M.current()
  return actions.resolve(vim.g.eldentree_region or read_saved())
end

function M.palette()
  return M.current().palette
end

-- the colorscheme spec hands us its static opts, we only swap the colors
function M.catppuccin_opts(base_opts, region)
  local opts = vim.deepcopy(base_opts)
  opts.color_overrides = { mocha = region.palette }
  return opts
end

local function load_colorscheme(region)
  require("catppuccin").setup(M.catppuccin_opts(M.base_opts or {}, region))
  vim.cmd.colorscheme("catppuccin")
end

-- every group starts at its old color and drifts to the new one, so the sky turns instead of blinking
local crossfade
local function fade_into(region, duration)
  if crossfade then crossfade:stop() end
  local before = vim.api.nvim_get_hl(0, {})
  load_colorscheme(region)
  local after = vim.api.nvim_get_hl(0, {})
  local names = blend.changed_groups(before, after)

  crossfade = motion.tween({
    duration = duration,
    easing   = "in_out_sine",
    frame_ms = 33,
    on_frame = function(t)
      for _, name in ipairs(names) do
        vim.api.nvim_set_hl(0, name, blend.mix_hl(before[name], after[name], t))
      end
    end,
  })
end

-- opts.save = false previews without remembering, opts.announce shows the region banner
function M.apply(name, opts)
  opts = opts or {}
  local region = actions.resolve(name)
  vim.g.eldentree_region = region.name
  if opts.save ~= false then save(region.name) end

  if not M.painted then
    M.painted = true
    load_colorscheme(region)
  else
    fade_into(region, opts.duration or 650)
  end
  -- the hub prints the region name, so redraw it if it is on screen
  if vim.bo.filetype == "snacks_dashboard" then Snacks.dashboard.update() end
  if opts.announce then require("core.banner").region(region) end
end

function M.cycle()
  M.apply(actions.next_name(M.current().name), { announce = true })
end

function M.pick()
  local original = M.current().name
  local confirmed = false

  local items = {}
  for index, region in ipairs(actions.REGIONS) do
    table.insert(items, { idx = index, text = region.title .. " " .. region.tagline, region = region })
  end

  Snacks.picker({
    title = "Choose your region",
    items = items,
    layout = { preset = "select" },
    format = function(item)
      local marker = item.region.name == original and "󰄳 " or "  "
      return {
        { marker, "SnacksPickerIcon" },
        { ("%-14s"):format(item.region.title), "SnacksPickerFile" },
        { item.region.tagline, "SnacksPickerComment" },
      }
    end,
    -- repaint while you scroll so you see the region before committing to it
    on_change = function(_, item)
      if item then M.apply(item.region.name, { save = false, duration = 220 }) end
    end,
    confirm = function(picker, item)
      confirmed = true
      picker:close()
      if item then M.apply(item.region.name, { announce = item.region.name ~= original }) end
    end,
    on_close = function()
      if not confirmed then vim.schedule(function() M.apply(original, { duration = 220 }) end) end
    end,
  })
end

function M.setup(base_opts)
  M.base_opts = base_opts
  M.apply(M.current().name, { save = false })

  vim.api.nvim_create_user_command("Region", function(cmd)
    if cmd.args == "" then return M.pick() end
    M.apply(cmd.args, { announce = true })
  end, {
    nargs = "?",
    complete = function() return actions.names() end,
    desc = "Switch Elden Ring region theme",
  })
end

return M
