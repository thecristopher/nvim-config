-- Elizabeth: everything the config says and shows while she plays her roles. Each region is a
-- stage and a costume, the Scarlet Witch, Ada, Shadowheart and Psylocke, and the world speaks
-- like a set: curtains between stages, a heart for a status and the afternoon sun to rest in.
return {
  name = "elizabeth",
  title = "Elizabeth",
  -- only played where vim.g.eldentree_opt_in names her, see lua/core/options.lua
  opt_in = true,

  regions = require("core.franchise.lore.elizabeth.regions"),
  skin = require("core.franchise.lore.elizabeth.skin"),
  voices = require("core.franchise.lore.elizabeth.voices"),
  lines = require("core.franchise.lore.elizabeth.lines"),

  -- which version of each mechanic this world plays
  mechanics = {
    travel = "curtain", -- velvet drapes close on one stage and part on the next
    boss = "scene", -- the villain steals the scene, every fix mends one of her broken hearts
    status = "heartbeat", -- a heart that beats calm and races with the errors
    rest = "golden_hour", -- the afternoon sun through the blinds, like in her photos
    ranking = true, -- every run is a take, and every take gets its review
  },

  -- hearts, and what you drop when you die is a broken one waiting to be mended
  currency = { glyph = "󰋑", stain = "󰋔" },

  -- back-to-basics: the names the HUD gives the drills, the coach is the region's character
  coach = {
    training = "Rehearsal",
    lessons = "Scripts",
    onsite = "Opening Night",
    concepts = "Wardrobe",
    hint = "A cue from the wings for %d XP?",
    buy = "Take it",
    leave = "I know my lines",
  },

  -- what the dressing room calls the HUD's tabs, the lessons tab takes coach.lessons
  hud_tabs = {
    tools = "Vanity",
    recent = "Recent Takes",
    keys = "Props",
    messages = "Notes",
    regions = "Roles",
  },

  -- Claude Code's statusline bars and spinner (claude/install.lua merges the verbs into settings)
  claude = {
    bars = { five_hour = "HEX", seven_day = "MOON" },
    verbs = {
      "Rewriting reality",
      "Weaving a hex",
      "Lacing the boots",
      "Fixing the wig",
      "Polishing the pauldrons",
      "Checking the grappling hook",
      "Praying to the moon",
      "Focusing the psychic blade",
      "Rehearsing the scene",
      "Finding the light",
      "Tying the cape",
    },
  },

  -- the now playing panel's title and what its lyrics say while they are not there
  music = {
    title = "Her Playlist",
    loading = "Humming the first notes…",
    missing = "No words for this one",
    instrumental = "Just the melody",
  },

  -- who stands against each stage when errors pile up
  bosses = {
    westview = "Agatha Harkness",
    separate_ways = "Pesanta",
    moonrise_towers = "Ketheric Thorm",
    danger_room = "Mister Sinister",
  },

  -- drift says where particles travel, speed is rows per second,
  -- from and to are the palette slots a particle glows between as it heats up
  weather = {
    -- chaos magic sparks rising through the golden hour
    westview = {
      glyphs = { "·", "∙", "•" },
      drift = "rise",
      speed = { 1.4, 3.6 },
      from = "peach",
      to = "yellow",
    },
    -- dust in a slanted sunbeam, barely moving
    separate_ways = {
      glyphs = { "·", "∙", "˙" },
      drift = "float",
      speed = { 0.2, 0.6 },
      from = "overlay2",
      to = "peach",
    },
    -- moonlight motes settling over the towers
    moonrise_towers = {
      glyphs = { "·", "∘", "˙" },
      drift = "fall",
      speed = { 0.6, 1.6 },
      from = "overlay2",
      to = "yellow",
    },
    -- psychic sparks flicking off the blade, quick and bright
    danger_room = {
      glyphs = { "·", "∙", "•" },
      drift = "rise",
      speed = { 2.4, 5.2 },
      from = "lavender",
      to = "yellow",
    },
  },

  -- the CI run of the branch, in the statusline
  ci = { running = "Rolling", passed = "That's a wrap", failed = "Cut" },

  -- review threads still open on the branch's PR, left on their lines
  threads = {
    title = "Director's Notes",
    resolved = "Note taken",
    none = "No notes on this PR",
  },

  -- who guards a merge conflict, and how many conflicted files the repo still holds
  conflict = { boss = "The Understudy", left = "%d scenes rewritten twice" },

  -- every kind of error you cleared becomes a villain she put down
  bestiary = {
    title = "Villains",
    empty = "No villains down yet",
    enemies = {
      "Hex Wraith",
      "Chaos Echo",
      "Sitcom Phantom",
      "Ganado",
      "Plaga",
      "Regenerador",
      "Shadow Cursed",
      "Intellect Devourer",
      "Mind Flayer",
      "Gnoll",
      "Absolute Cultist",
      "Shar's Shade",
      "Sentinel",
      "Marauder",
      "Wardrobe Moth",
      "Torn Seam",
      "Lost Prop",
      "Stage Fright",
    },
  },

  -- a focus block: the set goes quiet and the block gets its own rank
  expedition = {
    name = "Take",
    started = "Rolling, %d minutes on the clock",
    ended = "Cut, that's the take",
  },

  -- the days you worked, as a grid
  chronicle = { title = "Call Sheet" },

  banners = {
    felled = "VILLAIN DEFEATED",
    great = "STANDING OVATION",
    died = "CUT!",
    grace = "NEW STAGE FOUND",
    cleansed = "HEX BROKEN",
  },

  hub_messages = {
    "Chaos magic doesn't fix off by one errors",
    "No more bugs, she said, and there were none",
    "A grappling hook won't reach that deadline",
    "Selûne's light on your diff",
    "Fix the wig, then fix the build",
    "This scene needs another take",
    "Every role, one heart, zero warnings",
    "Focus the blade, then focus the diff",
    "The Danger Room resets, your tests should too",
    "The cape is velvet, the code is not",
    "What are you buying? A cleaner commit?",
    "Shadowheart doesn't trust that regex",
    "Westview had fewer side effects",
    "Lights, camera, refactor",
    "Your inventory is full of TODOs, love",
    "She already knew the bug was there",
    "Save the scene before the next costume change",
    "The moon says merge on Monday",
  },

  -- the blanks she fills when she leaves a note on a line
  message_templates = {
    "Note: %s",
    "Watch out for %s",
    "%s needs another take",
    "Hex %s before it spreads",
    "Don't trust %s",
    "%s, but with more style",
    "Rewrite %s, reality allows it",
    "Selûne guide %s",
    "I left %s for you",
    "Something about %s feels wrong…",
  },

  -- folders every project has get the place that fits them best
  landmarks = {
    tests = "Rehearsal Room",
    test = "Rehearsal Room",
    spec = "Rehearsal Room",
    __tests__ = "Rehearsal Room",
    docs = "Script Library",
    scripts = "Prop Table",
    node_modules = "Underdark",
    vendor = "Underdark",
    [".github"] = "Director's Booth",
    assets = "Wardrobe",
    images = "Wardrobe",
    config = "Dressing Room",
    lib = "Wanda's Basement",
    components = "Costume Rack",
    api = "The Radio Booth",
  },

  places = {
    "Westview",
    "The Hex",
    "Wundagore Mountain",
    "Darkhold Library",
    "Witches' Road",
    "Salazar Castle",
    "The Village",
    "The Island",
    "Ada's Hideout",
    "Merchant's Corner",
    "Moonrise Towers",
    "Last Light Inn",
    "The Underdark",
    "Grymforge",
    "Baldur's Gate",
    "House of Grief",
    "The Emerald Grove",
    "The Danger Room",
    "Xavier's Mansion",
    "Genosha",
    "The Dressing Room",
    "Backstage",
    "Golden Hour Hallway",
  },

  -- what the thing under the cursor would be in her wardrobe, most specific capture first
  item_categories = {
    { "function.method", "Spell" },
    { "function", "Hex" },
    { "constructor", "Costume" },
    { "type", "Role" },
    { "variable.parameter", "Prop" },
    { "variable.member", "Accessory" },
    { "property", "Accessory" },
    { "constant", "Heirloom" },
    { "boolean", "Heirloom" },
    { "number", "Heirloom" },
    { "module", "Stage" },
    { "keyword", "Cue" },
    { "string", "Line" },
    { "variable", "Item" },
  },

  -- what the editor's chrome says: mode names in the statusline, command line titles, the picker's
  -- preview and the notification titles per level
  chrome = {
    modes = {
      normal = "ROLE",
      insert = "SCRIPT",
      visual = "SPOTLIGHT",
      replace = "RECAST",
      command = "DIRECT",
      terminal = "BACKSTAGE",
    },
    cmdline = "Direction",
    search = "Search",
    examine = "Close up",
    history = "Call Sheet",
    notify = {
      info = "Cue",
      warn = "Careful",
      error = "Cut",
      debug = "Note",
      trace = "Script",
    },
  },

  words = {
    traveler = "Partner",
    hub = "Dressing Room",
    sites = "Stages",
    site = "Stage",
    sites_found = "stages found",
    no_sites = "No stages yet. Finding the light…",
    rise = "press any key, she's ready",
    choose_region = "Choose Role",
    region_prompt = "Choose her role",
    phantom = "Lines left by %s",
    past_self = "Your own last take",
    salute = "Elizabeth takes a bow for you",
    motion_on = "The scene moves again",
    motion_off = "Freeze frame",
    map = "Map",
    arts = "Commands",
    last_run = "Last take",
  },
}
