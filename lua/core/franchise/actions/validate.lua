-- Checks a franchise has everything the config reads from it, so a new one fails loudly in
-- :checkhealth instead of quietly mid session. Pure logic only.
local themes = require("core.themes.actions")
local voice = require("core.voice.actions")

local M = {}

M.SLOTS = {
  "base",
  "mantle",
  "crust",
  "surface0",
  "surface1",
  "surface2",
  "overlay0",
  "overlay1",
  "overlay2",
  "subtext0",
  "subtext1",
  "text",
  "yellow",
  "peach",
  "green",
  "teal",
  "lavender",
  "mauve",
  "red",
  "maroon",
  "rosewater",
  "flamingo",
  "blue",
  "sapphire",
  "sky",
  "pink",
}

M.BANNERS = { "felled", "great", "died", "grace", "cleansed" }
M.MECHANICS = { "travel", "boss", "status", "rest" }
M.SKIN = {
  "border",
  "ornament",
  "statusline",
  "tabs",
  "signs",
  "dashboard",
  "title",
  "music",
  "picker",
  "cmdline",
  "icons",
  "cursor",
  "glyphs",
}
-- what core/chrome reads: the mode names, the command line, the preview and the notification titles
M.CHROME = { "modes", "cmdline", "search", "examine", "history", "notify" }
M.CHROME_MODES = { "normal", "insert", "visual", "replace", "command", "terminal" }
M.CHROME_LEVELS = { "info", "warn", "error", "debug", "trace" }
-- what the now playing panel reads, its looks from the skin and its words from the lore
M.MUSIC_SKIN = { "bar", "divider", "sung" }
-- one glyph per diagnostic and notification level, see core/skin
M.ICONS = { "error", "warn", "info", "hint", "debug", "trace" }
-- the small marks core/skin/glyphs pushes into options and plugins
M.GLYPHS = { "indent", "scope", "list", "fold", "diff", "prompt", "keys", "scrollbar", "spinner" }
M.MUSIC_WORDS = { "title", "loading", "missing", "instrumental" }
M.LISTS = { "hub_messages", "message_templates", "places", "item_categories" }
-- back-to-basics reads the names the HUD gives the drills, the coach is the region's character
M.COACH = { "training", "lessons", "onsite", "concepts", "hint", "buy", "leave" }
-- the words of the modules that follow the work around the code: CI, review threads, conflicts,
-- the bestiary, focus blocks and the chronicle
M.QUESTS = {
  ci = { "running", "passed", "failed" },
  threads = { "title", "resolved", "none" },
  conflict = { "boss", "left" },
  bestiary = { "title", "empty", "enemies" },
  expedition = { "name", "started", "ended" },
  chronicle = { "title" },
}

M.WORDS = {
  "traveler",
  "hub",
  "sites",
  "site",
  "sites_found",
  "no_sites",
  "rise",
  "choose_region",
  "region_prompt",
  "phantom",
  "past_self",
  "salute",
  "motion_on",
  "motion_off",
  "map",
  "arts",
}

-- words only some mechanics read, so a franchise pays for what it plays
M.MECHANIC_WORDS = {
  { mechanic = "rest", value = "typewriter", words = { "ink_ribbons", "typewriter" } },
  { mechanic = "ranking", value = true, words = { "last_run", "rank", "saves", "fixes" } },
}

-- every version a mechanic or a skin piece can name, each one a module or a view that exists
M.CHOICES = {
  {
    table = "mechanics",
    key = "travel",
    label = "mechanics",
    values = { "fog", "door", "curtain" },
  },
  {
    table = "mechanics",
    key = "boss",
    label = "mechanics",
    values = { "duel", "stalker", "scene" },
  },
  {
    table = "mechanics",
    key = "status",
    label = "mechanics",
    values = { "grace", "ecg", "heartbeat" },
  },
  {
    table = "mechanics",
    key = "rest",
    label = "mechanics",
    values = { "embers", "typewriter", "golden_hour" },
  },
  {
    table = "skin",
    key = "dashboard",
    label = "skin",
    values = { "roundtable", "inventory", "wardrobe" },
  },
  {
    table = "skin",
    key = "picker",
    label = "skin",
    values = { "grace", "inventory", "vanity", "default" },
  },
}
M.TITLE_STYLES = { "shimmer", "drip", "marquee" }
-- the borders every plugin that frames a float accepts: nvim takes "bold" too, but nvim-ufo
-- refuses it and fails to load
M.BORDERS = { "rounded", "double", "single", "solid", "shadow", "none" }

local function unknown_choice(value, values, name, problems)
  if value ~= nil and not vim.tbl_contains(values, value) then
    table.insert(
      problems,
      ("%s is %s, it must be one of %s"):format(name, tostring(value), table.concat(values, ", "))
    )
  end
end

local function check_choices(lore, problems)
  for _, choice in ipairs(M.CHOICES) do
    local value = (lore[choice.table] or {})[choice.key]
    unknown_choice(value, choice.values, choice.label .. "." .. choice.key, problems)
  end
  local title = (lore.skin or {}).title or {}
  unknown_choice(title.style, M.TITLE_STYLES, "skin.title.style", problems)
  unknown_choice((lore.skin or {}).border, M.BORDERS, "skin.border", problems)
end

-- every line of lua/core/franchise/lines.lua, said in the franchise's own words
local function check_lines(lore, problems)
  local keys = vim.tbl_keys(require("core.franchise.lines"))
  table.sort(keys)
  for _, key in ipairs(keys) do
    local line = (lore.lines or {})[key]
    if line == nil or line == "" or (type(line) == "table" and #line == 0) then
      table.insert(problems, ("lines[%q] is missing"):format(key))
    end
  end
end

local function missing_keys(tbl, keys, label, problems)
  for _, key in ipairs(keys) do
    if tbl == nil or tbl[key] == nil then
      table.insert(problems, ("%s.%s is missing"):format(label, key))
    end
  end
end

local function check_words(lore, problems)
  missing_keys(lore.words, M.WORDS, "words", problems)
  for _, rule in ipairs(M.MECHANIC_WORDS) do
    if (lore.mechanics or {})[rule.mechanic] == rule.value then
      missing_keys(lore.words, rule.words, "words", problems)
    end
  end
end

local function check_music(lore, problems)
  if lore.skin and lore.skin.icons then
    missing_keys(lore.skin.icons, M.ICONS, "skin.icons", problems)
  end
  if lore.skin and lore.skin.glyphs then
    missing_keys(lore.skin.glyphs, M.GLYPHS, "skin.glyphs", problems)
  end
  if lore.skin and lore.skin.music then
    missing_keys(lore.skin.music, M.MUSIC_SKIN, "skin.music", problems)
  end
  if lore.music then
    missing_keys(lore.music, M.MUSIC_WORDS, "music", problems)
  end
end

local function check_chrome(lore, problems)
  missing_keys(lore.chrome, M.CHROME, "chrome", problems)
  if lore.chrome then
    missing_keys(lore.chrome.modes, M.CHROME_MODES, "chrome.modes", problems)
    missing_keys(lore.chrome.notify, M.CHROME_LEVELS, "chrome.notify", problems)
  end
end

local function check_palette(region, problems)
  local p = region.palette or {}
  for _, slot in ipairs(M.SLOTS) do
    if not (p[slot] or ""):match("^#%x%x%x%x%x%x$") then
      table.insert(problems, ("%s.palette.%s is not a #RRGGBB color"):format(region.name, slot))
      return
    end
  end
  if p.yellow == p.red then
    table.insert(problems, region.name .. " uses its accent as the error color")
  end
  if themes.contrast(themes.derive(p).separator, p.base) < 2.0 then
    table.insert(problems, region.name .. " separators are too faint on its base")
  end
  local panel = themes.contrast(themes.derive(p).panel, p.base)
  if panel < 1.07 or panel >= 1.15 then
    table.insert(
      problems,
      ("%s panels contrast %.2f, keep it between 1.07 and 1.15"):format(region.name, panel)
    )
  end
end

local function check_region(lore, region, portrait_exists, problems)
  missing_keys(
    region,
    { "name", "title", "tagline", "character", "portrait", "palette" },
    "region",
    problems
  )
  if not region.name then
    return
  end
  if not (lore.bosses or {})[region.name] then
    table.insert(problems, region.name .. " has no boss")
  end
  if not (lore.weather or {})[region.name] then
    table.insert(problems, region.name .. " has no weather")
  end
  for _, moment in ipairs(voice.MOMENTS) do
    if not voice.line(lore.voices, region.name, moment, 0, nil) then
      table.insert(problems, ("%s has no voice for %s"):format(region.name, moment))
    end
  end
  if region.portrait and portrait_exists and not portrait_exists(region.portrait) then
    table.insert(
      problems,
      ("%s portrait %s is not in images/portraits"):format(region.name, region.portrait)
    )
  end
  if region.figure and portrait_exists and not portrait_exists(region.figure) then
    table.insert(
      problems,
      ("%s figure %s is not in images/portraits"):format(region.name, region.figure)
    )
  end
  check_palette(region, problems)
end

local function check_quests(lore, problems)
  for name, keys in pairs(M.QUESTS) do
    missing_keys(lore[name], keys, name, problems)
  end
  local enemies = (lore.bestiary or {}).enemies
  if enemies ~= nil and (type(enemies) ~= "table" or #enemies == 0) then
    table.insert(problems, "bestiary.enemies is empty")
  end
end

local function check_regions(lore, portrait_exists, problems)
  if type(lore.regions) ~= "table" or #lore.regions == 0 then
    table.insert(problems, "regions is empty")
    return
  end
  local accents = {}
  for _, region in ipairs(lore.regions) do
    check_region(lore, region, portrait_exists, problems)
    local accent = (region.palette or {}).yellow
    if accent and accents[accent] then
      table.insert(problems, ("%s shares its accent with %s"):format(region.name, accents[accent]))
    end
    if accent then
      accents[accent] = region.name
    end
  end
end

--- Lists everything a franchise is missing or gets wrong, empty when it is ready to play.
---@param lore table franchise lore
---@param portrait_exists? fun(file: string): boolean checks a portrait file, skipped when nil
---@return string[] problems
function M.problems(lore, portrait_exists)
  local problems = {}
  missing_keys(lore, { "name", "title", "currency", "claude", "music" }, "lore", problems)
  missing_keys(lore.banners, M.BANNERS, "banners", problems)
  missing_keys(lore.mechanics, M.MECHANICS, "mechanics", problems)
  missing_keys(lore.skin, M.SKIN, "skin", problems)
  missing_keys(lore, M.LISTS, "lore", problems)
  missing_keys(lore.coach, M.COACH, "coach", problems)
  check_choices(lore, problems)
  check_lines(lore, problems)
  check_words(lore, problems)
  check_music(lore, problems)
  check_chrome(lore, problems)
  check_quests(lore, problems)
  check_regions(lore, portrait_exists, problems)
  return problems
end

return M
