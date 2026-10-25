-- Checks a franchise has everything the config reads from it, so a new one fails loudly in
-- :checkhealth instead of quietly mid session. Pure logic only.
local themes = require("core.themes.actions")

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
M.SKIN = { "border", "ornament", "statusline", "tabs", "signs", "dashboard", "title" }
M.LISTS = { "hub_messages", "message_templates", "places", "item_categories" }

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
}

-- words only some mechanics read, so a franchise pays for what it plays
M.MECHANIC_WORDS = {
  { mechanic = "rest", value = "typewriter", words = { "ink_ribbons", "typewriter" } },
  { mechanic = "ranking", value = true, words = { "last_run" } },
}

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
  if region.portrait and portrait_exists and not portrait_exists(region.portrait) then
    table.insert(
      problems,
      ("%s portrait %s is not in images/portraits"):format(region.name, region.portrait)
    )
  end
  check_palette(region, problems)
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
  missing_keys(lore, { "name", "title", "currency" }, "lore", problems)
  missing_keys(lore.banners, M.BANNERS, "banners", problems)
  missing_keys(lore.mechanics, M.MECHANICS, "mechanics", problems)
  missing_keys(lore.skin, M.SKIN, "skin", problems)
  missing_keys(lore, M.LISTS, "lore", problems)
  check_words(lore, problems)
  check_regions(lore, portrait_exists, problems)
  return problems
end

return M
