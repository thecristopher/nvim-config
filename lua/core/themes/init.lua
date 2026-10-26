-- Region switcher: one region per day, recolors catppuccin, and lets you
-- browse regions live with <leader>ut. Everything else follows the ColorScheme event.
local actions = require("core.themes.actions")
local motion = require("core.motion")
local blend = require("core.motion.actions")

local M = {}

local state_file = vim.fn.stdpath("state") .. "/eldentree_region"

local function today()
  return os.date("%Y-%m-%d")
end

-- the region picked today, nil when nothing was picked or the pick belongs to another day
local function read_choice()
  local ok, lines = pcall(vim.fn.readfile, state_file, "", 1)
  return actions.choice_for(ok and lines[1] or nil, today())
end

local function save(name)
  pcall(vim.fn.writefile, { actions.encode_choice(today(), name) }, state_file)
end

local function of_the_day()
  return actions.of_the_day(today(), require("core.franchise").name(), actions.names())
end

function M.current()
  return actions.resolve(vim.g.eldentree_region or read_choice() or of_the_day())
end

function M.palette()
  return M.current().palette
end

-- the colorscheme spec hands us its static opts, we only swap the colors
function M.catppuccin_opts(base_opts, region)
  local opts = vim.deepcopy(base_opts)
  opts.color_overrides = { mocha = region.palette }
  -- one cache per region, so previewing regions loads compiled colors instead of recompiling
  opts.compile_path = vim.fn.stdpath("cache") .. "/catppuccin/" .. region.name
  return opts
end

local function load_colorscheme(region)
  -- the compiler caches the options it first saw, so it would keep writing to the first region's path
  package.loaded["catppuccin.lib.compiler"] = nil
  require("catppuccin").setup(M.catppuccin_opts(M.base_opts or {}, region))
  vim.cmd.colorscheme("catppuccin")
end

-- every group starts at its old color and drifts to the new one, so the sky turns instead of blinking
local crossfade
local function fade_into(region, duration)
  if crossfade then
    crossfade:stop()
  end
  local before = vim.api.nvim_get_hl(0, {})
  load_colorscheme(region)
  local after = vim.api.nvim_get_hl(0, {})
  local names = blend.changed_groups(before, after)

  crossfade = motion.tween({
    duration = duration,
    easing = "in_out_sine",
    frame_ms = 33,
    on_frame = function(t)
      for _, name in ipairs(names) do
        vim.api.nvim_set_hl(0, name, blend.mix_hl(before[name], after[name], t))
      end
    end,
    -- plugins that cache colors read them at ColorScheme, which fired before the fade began
    on_done = function()
      vim.api.nvim_exec_autocmds("User", { pattern = "EldentreeRegionSettled", modeline = false })
    end,
  })
end

-- opts.save = false previews without keeping it for the rest of the day, opts.announce shows the
-- region banner
function M.apply(name, opts)
  opts = opts or {}
  local region = actions.resolve(name)
  vim.g.eldentree_region = region.name
  if opts.save ~= false then
    save(region.name)
  end

  if not M.painted then
    M.painted = true
    load_colorscheme(region)
  else
    fade_into(region, opts.duration or 650)
  end
  -- the HUD shows the region and its champion, so it redraws when it is open
  require("core.hud").refresh(true)
  if opts.announce then
    require("core.banner").region(region)
  end
end

function M.cycle()
  M.apply(actions.next_name(M.current().name), { announce = true })
end

function M.pick()
  local original = M.current().name
  local confirmed = false

  local items = {}
  for index, region in ipairs(actions.regions()) do
    table.insert(
      items,
      { idx = index, text = region.title .. " " .. region.tagline, region = region }
    )
  end

  Snacks.picker({
    title = require("core.franchise").current().words.region_prompt,
    items = items,
    layout = { preset = "select" },
    format = function(item)
      local marker = item.region.name == original and "󰄳 " or "  "
      return {
        { marker, "SnacksPickerIcon" },
        { ("%-23s"):format(item.region.title), "SnacksPickerFile" },
        { item.region.tagline, "SnacksPickerComment" },
      }
    end,
    -- repaint while you scroll so you see the region before committing to it
    on_change = function(_, item)
      if item then
        M.apply(item.region.name, { save = false, duration = 220 })
      end
    end,
    confirm = function(picker, item)
      confirmed = true
      picker:close()
      if item then
        M.apply(item.region.name, { announce = item.region.name ~= original })
      end
    end,
    on_close = function()
      if not confirmed then
        vim.schedule(function()
          M.apply(original, { duration = 220 })
        end)
      end
    end,
  })
end

-- one region all day: the one picked today, or the day's own, and vim.g.eldentree_region pins one
local function starting_region()
  if M.pinned then
    return vim.g.eldentree_region
  end
  return read_choice() or of_the_day()
end

--- Moves into the new franchise's world after :Franchise, announcing where you landed.
function M.follow_franchise()
  M.apply(starting_region(), { announce = true })
end

function M.setup(base_opts)
  M.base_opts = base_opts
  M.pinned = vim.g.eldentree_region ~= nil
  -- the day's region stays for the whole session, traveling between repos never changes it
  M.apply(starting_region())

  vim.api.nvim_create_user_command("Region", function(cmd)
    if cmd.args == "" then
      return M.pick()
    end
    M.apply(cmd.args, { announce = true })
  end, {
    nargs = "?",
    complete = function()
      return actions.names()
    end,
    desc = "Switch region theme",
  })
end

return M
