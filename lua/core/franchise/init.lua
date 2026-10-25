-- Picks the franchise the whole config speaks: a new one every day, pinned with
-- vim.g.eldentree_franchise, or switched with :Franchise until midnight.
local actions = require("core.franchise.actions")

local M = {}

local state_file = vim.fn.stdpath("state") .. "/eldentree_franchise"
local active

local function today()
  return os.date("%Y-%m-%d")
end

local function read_choice()
  local ok, lines = pcall(vim.fn.readfile, state_file, "", 1)
  return ok and actions.choice_for(lines[1], today()) or nil
end

--- Returns the name of the franchise in use right now.
---@return string
function M.name()
  if vim.g.eldentree_franchise then
    return actions.resolve(vim.g.eldentree_franchise)
  end
  active = active or read_choice() or actions.of_the_day(os.date("*t"))
  return active
end

--- Returns the lore of the franchise in use: regions, bosses, weather, banners and words.
---@return table
function M.current()
  return actions.lore(M.name())
end

--- Returns which version of a mechanic the franchise plays, like "door" for travel.
---@param name string mechanic name: travel, boss, status, rest or ranking
---@return any
function M.mechanic(name)
  return M.current().mechanics[name]
end

--- Switches franchise for the rest of the day and repaints the editor in it.
--- Everything that dresses up per franchise listens to the EldentreeFranchise event.
---@param name string franchise name
function M.switch(name)
  if vim.g.eldentree_franchise then
    return vim.notify(
      "vim.g.eldentree_franchise pins " .. M.current().title,
      vim.log.levels.WARN,
      { title = "Eldentree" }
    )
  end
  active = actions.resolve(name)
  pcall(vim.fn.writefile, { actions.encode_choice(today(), active) }, state_file)
  require("core.themes").follow_franchise()
  vim.api.nvim_exec_autocmds("User", { pattern = "EldentreeFranchise", modeline = false })
end

function M.pick()
  vim.ui.select(actions.names(), {
    prompt = "Choose today's franchise",
    format_item = function(name)
      return actions.lore(name).title
    end,
  }, function(name)
    if name then
      M.switch(name)
    end
  end)
end

local function lore_dir(name)
  return vim.fn.stdpath("config") .. "/lua/core/franchise/lore/" .. name
end

--- Creates a new franchise from the template and opens its lore to fill in.
---@param text string the franchise's name as a person writes it, like "Silent Hill"
function M.create(text)
  local name = actions.slug(text)
  if not name then
    return vim.notify("Name the franchise, like :Franchise new Silent Hill", vim.log.levels.WARN)
  end
  local dir = lore_dir(name)
  if vim.uv.fs_stat(dir) then
    return vim.notify(name .. " already exists", vim.log.levels.WARN, { title = "Eldentree" })
  end

  vim.fn.mkdir(dir, "p")
  local template = vim.fn.stdpath("config") .. "/lua/core/franchise/template/"
  for _, file in ipairs({ "init.lua", "regions.lua", "skin.lua" }) do
    local text_lines = vim.fn.readfile(template .. file)
    local filled =
      vim.split(actions.fill_template(table.concat(text_lines, "\n"), name), "\n", { plain = true })
    vim.fn.writefile(filled, dir .. "/" .. file)
  end
  actions.rediscover()
  vim.cmd.edit(vim.fn.fnameescape(dir .. "/init.lua"))
  vim.notify(
    ("%s is born. Fill its lore, then :checkhealth eldentree"):format(actions.title(name)),
    vim.log.levels.INFO,
    { title = "Eldentree" }
  )
end

local function run(cmd)
  local first, rest = cmd.args:match("^(%S*)%s*(.-)$")
  if first == "" then
    return M.pick()
  end
  if first == "new" then
    return M.create(rest)
  end
  M.switch(first)
end

function M.setup()
  vim.api.nvim_create_user_command("Franchise", run, {
    nargs = "*",
    complete = function()
      return vim.list_extend({ "new" }, vim.deepcopy(actions.names()))
    end,
    desc = "Switch today's franchise, or :Franchise new <name> to create one",
  })
end

return M
