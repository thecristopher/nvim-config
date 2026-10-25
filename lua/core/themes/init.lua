-- Region switcher: remembers your region, recolors catppuccin, and lets you
-- browse regions live with <leader>ut. Everything else follows the ColorScheme event.
local actions = require("core.themes.actions")
local motion = require("core.motion")
local blend = require("core.motion.actions")

local M = {}

local state_file = vim.fn.stdpath("state") .. "/eldentree_region"

local function read_saved()
  local ok, lines = pcall(vim.fn.readfile, state_file, "", 1)
  return ok and lines[1] or nil
end

local function save(name)
  pcall(vim.fn.writefile, { name }, state_file)
end

-- each franchise remembers its own picks, Elden Ring keeps the file it always had
local function projects_file()
  local name = require("core.franchise").name()
  local suffix = name == "elden_ring" and "" or "_" .. name
  return vim.fn.stdpath("state") .. "/eldentree_project_regions" .. suffix .. ".json"
end

local function read_projects()
  local ok, lines = pcall(vim.fn.readfile, projects_file())
  if not ok then
    return {}
  end
  local decoded_ok, decoded = pcall(vim.json.decode, table.concat(lines, "\n"))
  return (decoded_ok and type(decoded) == "table") and decoded or {}
end

-- the repo you are standing in, nil outside of one or with vim.g.eldentree_region_per_project = false
local function project_root()
  if vim.g.eldentree_region_per_project == false then
    return nil
  end
  return require("core.repos").root()
end

local function remember_for_project(name)
  local root = project_root()
  if not root then
    return
  end
  local chosen = read_projects()
  chosen[root] = name
  pcall(vim.fn.writefile, { vim.json.encode(chosen) }, projects_file())
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

-- opts.save = false previews without remembering, opts.remember also ties the region to this project,
-- opts.announce shows the region banner
function M.apply(name, opts)
  opts = opts or {}
  local region = actions.resolve(name)
  vim.g.eldentree_region = region.name
  if opts.save ~= false then
    save(region.name)
  end
  if opts.remember then
    remember_for_project(region.name)
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
  M.apply(actions.next_name(M.current().name), { announce = true, remember = true })
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
        M.apply(item.region.name, { announce = item.region.name ~= original, remember = true })
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

-- a repo always wears its own region, anywhere else a fresh roll every launch tells terminals apart,
-- and setting vim.g.eldentree_region pins one everywhere
local function starting_region()
  if M.pinned then
    return vim.g.eldentree_region
  end
  local root = project_root()
  if root then
    return actions.project_region(root, read_projects())
  end
  math.randomseed(vim.uv.hrtime() % 2 ^ 31)
  return actions.random_name(read_saved(), math.random)
end

--- Moves into the new franchise's world after :Franchise, announcing where you landed.
function M.follow_franchise()
  M.apply(starting_region(), { announce = true })
end

function M.setup(base_opts)
  M.base_opts = base_opts
  M.pinned = vim.g.eldentree_region ~= nil
  -- the region you start in stays for the whole session, traveling between repos never changes it
  M.apply(starting_region())

  vim.api.nvim_create_user_command("Region", function(cmd)
    if cmd.args == "" then
      return M.pick()
    end
    M.apply(cmd.args, { announce = true, remember = true })
  end, {
    nargs = "?",
    complete = function()
      return actions.names()
    end,
    desc = "Switch region theme",
  })
end

return M
