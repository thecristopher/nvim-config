-- Glyphs lost on the way into a file leave an empty string behind, and the plugin then draws
-- nothing where an icon belonged. This walks every Lua file under lua/ (the lore skins included) and
-- fails on any icon, glyph, sign or symbol key set to "" or " " that is not blank on purpose.

-- keys whose blank value means an icon went missing
local GLYPH_KEYS = {
  "icon",
  "glyph",
  "symbol",
  "sign",
  "marker",
  "fold_closed",
  "fold_open",
  "separator",
}
-- the levels and git states that hold glyphs in icon tables
local GLYPH_NAMES = {
  error = true,
  warn = true,
  info = true,
  hint = true,
  debug = true,
  trace = true,
  added = true,
  modified = true,
  removed = true,
  deleted = true,
  staged = true,
  unstaged = true,
  unmerged = true,
  renamed = true,
  ignored = true,
  conflict = true,
  untracked = true,
}

-- blank on purpose: "file:line" with a reason each
local ALLOWED = {
  -- snacks' own notifier icons stay blank so the franchise's level glyph wins, see core/chrome
  ["lua/plugins/snacks.lua:26"] = true,
  ["lua/plugins/snacks.lua:27"] = true,
  ["lua/plugins/snacks.lua:28"] = true,
  ["lua/plugins/snacks.lua:29"] = true,
  ["lua/plugins/snacks.lua:30"] = true,
  -- the Lands Between keep the gutter empty, tiny-inline-diagnostic speaks for the errors
  ["lua/core/franchise/lore/elden_ring/skin.lua:15"] = true,
}

local function holds_glyph(key)
  if GLYPH_NAMES[key] then
    return true
  end
  for _, part in ipairs(GLYPH_KEYS) do
    if key:find(part, 1, true) then
      return true
    end
  end
  return false
end

-- every blank glyph on one line, as "file:line key"
local function blanks_in(file, number, line, found)
  for key, value in line:gmatch('([%w_]+)%s*=%s*"([^"]*)"') do
    local blank = value == "" or value == " "
    local place = file .. ":" .. number
    if blank and holds_glyph(key) and not ALLOWED[place] then
      table.insert(found, place .. " " .. key)
    end
  end
end

local function lua_files()
  return vim.fs.find(function(name)
    return name:match("%.lua$") ~= nil
  end, { path = "lua", type = "file", limit = math.huge })
end

describe("glyphs", function()
  it("leaves no icon blank where Claire, Malenia and Inde expect one", function()
    local found = {}
    for _, path in ipairs(lua_files()) do
      local file = vim.fs.normalize(path):gsub("^%./", "")
      for number, line in ipairs(vim.fn.readfile(path)) do
        blanks_in(file, number, line, found)
      end
    end
    table.sort(found)
    assert.same({}, found)
  end)
end)
