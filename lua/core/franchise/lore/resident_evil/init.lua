-- Resident Evil: everything the config says and shows while it survives Raccoon City.
return {
  name = "resident_evil",
  title = "Resident Evil",

  regions = require("core.franchise.lore.resident_evil.regions"),
  skin = require("core.franchise.lore.resident_evil.skin"),

  -- which version of each mechanic this world plays
  mechanics = {
    travel = "door", -- the screen goes dark and a door creaks open
    boss = "stalker", -- the boss hunts you instead of standing still
    status = "ecg", -- the health ECG: Fine, Caution, Danger
    rest = "typewriter", -- the safe room typewriter writes your save
    ranking = true, -- the results screen ranks the last run
  },

  -- pesetas, and what you drop when you die is still yours to reclaim
  currency = { glyph = "₧", stain = "☣" },

  -- back-to-basics: who coaches the daily drills and what the HUD calls them
  coach = { persona = "claire", training = "Training Room", lessons = "Lesson Files" },

  -- Claude Code's statusline bars and spinner (claude/install.lua merges the verbs into settings)
  claude = {
    bars = { five_hour = "AMMO", seven_day = "HERBS" },
    verbs = {
      "Checking the map",
      "Combining herbs",
      "Saving at the typewriter",
      "Solving the crest puzzle",
      "Reloading",
      "Talking to the merchant",
      "Opening the door slowly",
      "Sorting the item box",
      "Outrunning Nemesis",
      "Reading a file",
    },
  },

  -- the now playing panel's title and what its lyrics say while they are not there
  music = {
    title = "Save Room",
    loading = "Searching the files…",
    missing = "No file on this song",
    instrumental = "Instrumental tape",
  },

  -- the merchant shows up every time your pesetas cross another MERCHANT_EVERY
  merchant = {
    "What are ya buyin'?",
    "Got a selection of good things on sale, stranger!",
    "Ahh, I'll buy it at a high price!",
    "Heh heh heh, thank you!",
    "Is that all, stranger?",
  },

  -- how a banner kind moves in this world, merged over its defaults
  banner_styles = {
    died = { drip = true, stagger = 0, letter_ms = 500, fade_in = 300, duration = 4600 },
  },

  -- who stalks each location when errors pile up
  bosses = {
    raccoon_city = "Nemesis T-Type",
    rpd = "Mr. X, Tyrant T-00",
    spencer_mansion = "Tyrant T-002",
    umbrella_lab = "William Birkin, G-Type",
    salazar_castle = "Ramon Salazar",
    the_island = "Osmund Saddler",
    village = "Lady Dimitrescu",
  },

  -- drift says where particles travel, speed is rows per second,
  -- from and to are the palette slots a particle glows between as it heats up
  weather = {
    raccoon_city = {
      glyphs = { "·", "∙", "•" },
      drift = "rise",
      speed = { 2.5, 5.5 },
      from = "yellow",
      to = "peach",
    },
    rpd = {
      glyphs = { "·", "╎", "│" },
      drift = "fall",
      speed = { 9.0, 15.0 },
      from = "overlay2",
      to = "sky",
    },
    spencer_mansion = {
      glyphs = { "·", "∙", "•" },
      drift = "float",
      speed = { 0.1, 0.4 },
      from = "overlay2",
      to = "yellow",
    },
    umbrella_lab = {
      glyphs = { "·", "∘", "○" },
      drift = "float",
      speed = { 0.2, 0.6 },
      from = "overlay1",
      to = "yellow",
    },
    salazar_castle = {
      glyphs = { "·", "•", "●" },
      drift = "fall",
      speed = { 1.5, 3.5 },
      from = "maroon",
      to = "yellow",
    },
    the_island = {
      glyphs = { "·", "∙", "˙" },
      drift = "float",
      speed = { 0.4, 1.2 },
      from = "overlay2",
      to = "yellow",
    },
    village = {
      glyphs = { "·", "∗", "❄" },
      drift = "fall",
      speed = { 0.6, 1.6 },
      from = "peach",
      to = "yellow",
    },
  },

  banners = {
    felled = "THREAT NEUTRALIZED",
    great = "MISSION COMPLETE",
    died = "YOU ARE DEAD",
    grace = "SAFE ROOM FOUND",
    cleansed = "T-VIRUS CONTAINED",
  },

  hub_messages = {
    "Itchy. Tasty. Undefined.",
    "What are ya buyin'? A refactor?",
    "Stranger, stranger, now that's a stack trace",
    "You were almost a merge conflict sandwich!",
    "Don't open that door: legacy code",
    "Save often, ink ribbons are scarce",
    "Herbs don't heal off by one errors",
    "Your inventory is full of TODOs",
    "Combine a green and a red test for full health",
    "The T-Virus reached production...",
    "Where's everyone going? Bingo? No, standup",
    "Hunnigan, I need a code review",
    "Stay away from that Friday deploy",
    "Buy low, refactor high, thank you",
    "Something is moving in the logs...",
    "The lights are back on: tests pass",
  },

  -- the blanks survivors fill when they leave a note on a line
  message_templates = {
    "Note: %s",
    "Watch out for %s",
    "%s in the next room",
    "Save before %s",
    "Don't trust %s",
    "%s needs a key",
    "Combine %s with care",
    "Itchy, tasty %s",
    "Something about %s feels wrong...",
    "Ammo running low, %s",
  },

  -- folders every project has get the place that fits them best
  landmarks = {
    tests = "Umbrella Testing Facility",
    test = "Umbrella Testing Facility",
    spec = "Umbrella Testing Facility",
    __tests__ = "Umbrella Testing Facility",
    docs = "RPD Library",
    scripts = "Safe Room",
    node_modules = "Raccoon City Sewers",
    vendor = "Raccoon City Sewers",
    [".github"] = "S.T.A.R.S. Office",
    assets = "Art Gallery",
    images = "Art Gallery",
    config = "Main Hall",
    lib = "Umbrella Headquarters",
    components = "Clock Tower",
    api = "Communications Room",
  },

  places = {
    "Raccoon Police Department",
    "Spencer Mansion",
    "Arklay Laboratory",
    "Guardhouse",
    "St. Michael Clock Tower",
    "Raccoon Park",
    "Dead Factory",
    "NEST",
    "Raccoon General Hospital",
    "Kendo Gun Shop",
    "Orphanage",
    "Water Treatment Plant",
    "Rockfort Island",
    "Antarctic Base",
    "Salazar Castle",
    "The Village",
    "The Island",
    "Kijuju",
    "Baker House",
    "Castle Dimitrescu",
    "House Beneviento",
    "Moreau's Reservoir",
    "Heisenberg's Factory",
    "Raccoon City Sewers",
    "Umbrella Training Facility",
    "Ashford Mansion",
    "Queen Zenobia",
    "Tall Oaks",
  },

  -- what the thing under the cursor would be in your attaché case, most specific capture first
  item_categories = {
    { "function.method", "Custom Part" },
    { "function", "Weapon" },
    { "constructor", "Crafting Recipe" },
    { "type", "File" },
    { "variable.parameter", "Ammo" },
    { "variable.member", "Key Item" },
    { "property", "Key Item" },
    { "constant", "Treasure" },
    { "boolean", "Treasure" },
    { "number", "Treasure" },
    { "module", "Map" },
    { "keyword", "Ink Ribbon" },
    { "string", "Memo" },
    { "variable", "Item" },
  },

  words = {
    traveler = "Survivor",
    hub = "Safe Room",
    sites = "Safe Rooms",
    site = "Safe Room",
    sites_found = "safe rooms found",
    no_sites = "No safe rooms yet. Searching the city…",
    rise = "press any key to leave the safe room",
    choose_region = "Choose Location",
    region_prompt = "Choose your location",
    phantom = "Files left by %s",
    past_self = "Your own diary entry",
    salute = "S.T.A.R.S. salutes you",
    motion_on = "Raccoon City wakes up",
    motion_off = "Time stops in the safe room",
    map = "Map",
    ink_ribbons = "Ink Ribbons",
    typewriter = "Will you use an Ink Ribbon?",
    last_run = "Last run",
  },
}
