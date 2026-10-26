-- :checkhealth eldentree: every franchise's lore, plus what the terminal can do for them.
local M = {}

local function portrait_exists(file)
  return vim.fn.filereadable(vim.fn.stdpath("config") .. "/images/portraits/" .. file) == 1
end

local function check_franchises()
  local actions = require("core.franchise.actions")
  local validate = require("core.franchise.actions.validate")
  actions.rediscover()
  for _, name in ipairs(actions.names()) do
    vim.health.start("Franchise: " .. name)
    local ok, lore = pcall(actions.lore, name)
    if not ok then
      vim.health.error("lore does not load: " .. tostring(lore))
    else
      local problems = validate.problems(lore, portrait_exists)
      if #problems == 0 then
        vim.health.ok(("%s is ready, %d regions"):format(lore.title, #lore.regions))
      end
      for _, problem in ipairs(problems) do
        vim.health.warn(problem)
      end
    end
  end
end

local function check_terminal()
  vim.health.start("Terminal")
  local terminal = require("core.terminal")
  vim.health.info("running in " .. terminal.name())
  local has_magick = vim.fn.executable("magick") == 1 or vim.fn.executable("convert") == 1
  if terminal.supports_images() and has_magick then
    vim.health.ok("portraits render as real images")
  elseif terminal.supports_images() and vim.fn.executable("chafa") == 1 then
    vim.health.warn(
      "portraits render with chafa, install ImageMagick (`brew install imagemagick`) to show them as real images"
    )
  elseif vim.fn.executable("chafa") == 1 then
    vim.health.ok("portraits render with chafa, Kitty or Ghostty would show them as real images")
  else
    vim.health.warn("chafa is not installed, the hub shows no portraits")
  end
  if vim.fn.executable("afplay") == 1 or vim.fn.executable("paplay") == 1 then
    vim.health.ok("sounds can play, drop files into sounds/<franchise>/")
  else
    vim.health.info("no audio player found, sounds stay quiet")
  end
end

function M.check()
  check_franchises()
  check_terminal()
end

return M
