-- Elden Ring: everything the config says and shows while it lives in the Lands Between.
return {
  name = "elden_ring",
  title = "Elden Ring",

  regions = require("core.franchise.lore.elden_ring.regions"),
  skin = require("core.franchise.lore.elden_ring.skin"),

  -- which version of each mechanic this world plays
  mechanics = {
    travel = "fog", -- a fog wall rolls over the editor
    boss = "duel", -- a health bar you chip down fix by fix
    status = "grace", -- the breathing grace glyph in the statusline
    rest = "embers", -- embers rise while you rest
    ranking = false, -- no results screen in the Lands Between
  },

  currency = { glyph = "◈", stain = "󰈸" },

  -- back-to-basics: who coaches the daily drills and what the HUD calls them
  coach = { persona = "malenia", training = "Sparring", lessons = "Battle Notes" },

  -- Claude Code's statusline bars and spinner (claude/install.lua merges the verbs into settings)
  claude = {
    bars = { five_hour = "FP", seven_day = "ST" },
    verbs = {
      "Seeking grace",
      "Two-handing the bug",
      "Rolling through the fog",
      "Reading a message on the ground",
      "Summoning spirit ashes",
      "Parrying the stack trace",
      "Leveling Mind",
      "Asking Melina",
      "Resting at a Site of Grace",
      "Trying finger but hole",
    },
  },

  -- the now playing panel's title and what its lyrics say while they are not there
  music = {
    title = "Song of Grace",
    loading = "Seeking the verses…",
    missing = "No verses survive for this song",
    instrumental = "A hymn without words",
  },

  -- who guards each region when errors pile up
  bosses = {
    leyndell = "Morgott, the Omen King",
    haligtree = "Malenia, Blade of Miquella",
    raya_lucaria = "Rennala, Queen of the Full Moon",
    caelid = "Starscourge Radahn",
    mohgwyn = "Mohg, Lord of Blood",
    ordina = "Commander Niall",
    limgrave = "Margit, the Fell Omen",
    stormveil = "Godrick the Grafted",
    volcano_manor = "Rykard, Lord of Blasphemy",
    nokron = "Mimic Tear",
    farum_azula = "Maliketh, the Black Blade",
  },

  -- drift says where particles travel, speed is rows per second,
  -- from and to are the palette slots a particle glows between as it heats up
  weather = {
    leyndell = {
      glyphs = { "·", "∙", "•" },
      drift = "rise",
      speed = { 1.6, 4.0 },
      from = "peach",
      to = "yellow",
    },
    haligtree = {
      glyphs = { "·", "✿", "❀" },
      drift = "fall",
      speed = { 0.8, 2.0 },
      from = "red",
      to = "yellow",
    },
    raya_lucaria = {
      glyphs = { "·", "✧", "✦" },
      drift = "float",
      speed = { 0.2, 0.6 },
      from = "lavender",
      to = "yellow",
    },
    caelid = {
      glyphs = { "·", "∙", "•" },
      drift = "rise",
      speed = { 3.0, 6.0 },
      from = "red",
      to = "peach",
    },
    mohgwyn = {
      glyphs = { "·", "•", "●" },
      drift = "fall",
      speed = { 2.5, 5.0 },
      from = "maroon",
      to = "yellow",
    },
    ordina = {
      glyphs = { "·", "∗", "❄" },
      drift = "fall",
      speed = { 0.6, 1.6 },
      from = "overlay2",
      to = "text",
    },
    limgrave = {
      glyphs = { "·", "∙", "❦" },
      drift = "fall",
      speed = { 0.8, 2.2 },
      from = "peach",
      to = "yellow",
    },
    stormveil = {
      glyphs = { "·", "╎", "│" },
      drift = "fall",
      speed = { 9.0, 15.0 },
      from = "overlay2",
      to = "sky",
    },
    volcano_manor = {
      glyphs = { "·", "•", "●" },
      drift = "rise",
      speed = { 2.5, 5.5 },
      from = "red",
      to = "yellow",
    },
    nokron = {
      glyphs = { "·", "✧", "✦" },
      drift = "float",
      speed = { 0.1, 0.4 },
      from = "overlay2",
      to = "yellow",
    },
    farum_azula = {
      glyphs = { "·", "✧", "ϟ" },
      drift = "float",
      speed = { 0.3, 0.9 },
      from = "lavender",
      to = "yellow",
    },
  },

  banners = {
    felled = "ENEMY FELLED",
    great = "GREAT ENEMY FELLED",
    died = "YOU DIED",
    grace = "LOST GRACE DISCOVERED",
    cleansed = "SCARLET ROT CLEANSED",
  },

  -- appraisals not included, you will have to imagine the "Good" count yourself
  hub_messages = {
    "Try refactoring, but hole",
    "Praise the green test!",
    "Be wary of null",
    "Liar ahead: TODO",
    "Could this be a race condition?",
    "If only I had a type system...",
    "Merge conflict ahead, therefore try retreat",
    "Visions of production...",
    "Time for git blame",
    "Hidden path ahead: the README",
    "Be wary of Friday deploys",
    "Praise the linter!",
    "Ahh, regex...",
    "Behold, legacy code!",
    "Seek :help",
    "Didn't expect an off by one...",
    "Guidance of grace shall lead the way",
    "Rise, and let grace light your path",
    "Fear not the stack trace, Tarnished",
    "Seek the lands between your functions",
  },

  -- the blanks players fill when they leave a message on a line
  message_templates = {
    "Try %s",
    "Be wary of %s",
    "%s ahead",
    "Praise the %s!",
    "Could this be a %s?",
    "If only I had a %s...",
    "Visions of %s...",
    "Time for %s",
    "Behold, %s!",
    "Seek %s",
    "Didn't expect %s...",
  },

  -- folders every project has get the place that fits them best
  landmarks = {
    tests = "Stranded Graveyard",
    test = "Stranded Graveyard",
    spec = "Stranded Graveyard",
    __tests__ = "Stranded Graveyard",
    docs = "Raya Lucaria Academy",
    scripts = "Roundtable Hold",
    node_modules = "Lake of Rot",
    vendor = "Lake of Rot",
    [".github"] = "Church of Elleh",
    assets = "Siofra River",
    images = "Siofra River",
    config = "Caria Manor",
    lib = "Leyndell, Royal Capital",
    components = "Sellia, Town of Sorcery",
    api = "Bellum Highway",
  },

  places = {
    "Stormhill",
    "Weeping Peninsula",
    "Castle Morne",
    "Liurnia of the Lakes",
    "Caria Manor",
    "Altus Plateau",
    "Mt. Gelmir",
    "Siofra River",
    "Ainsel River",
    "Deeproot Depths",
    "Lake of Rot",
    "Consecrated Snowfield",
    "Mohgwyn Palace",
    "Raya Lucaria Academy",
    "Redmane Castle",
    "Sellia, Town of Sorcery",
    "Dragonbarrow",
    "Murkwater Cave",
    "Stranded Graveyard",
    "Church of Elleh",
    "Gatefront Ruins",
    "Agheel Lake",
    "Shaded Castle",
    "Elphael, Brace of the Haligtree",
    "Volcano Manor",
    "Nokstella, Eternal City",
    "Mountaintops of the Giants",
    "Forbidden Lands",
    "Academy Gate Town",
    "Bellum Highway",
    "Fort Haight",
    "Stormveil Castle",
    "Castle Sol",
    "Ordina, Liturgical Town",
  },

  -- what the thing under the cursor would be in your inventory, most specific capture first
  item_categories = {
    { "function.method", "Sorcery" },
    { "function", "Incantation" },
    { "constructor", "Incantation" },
    { "type", "Talisman" },
    { "variable.parameter", "Ash of War" },
    { "variable.member", "Key Item" },
    { "property", "Key Item" },
    { "constant", "Great Rune" },
    { "boolean", "Great Rune" },
    { "number", "Great Rune" },
    { "module", "Map Fragment" },
    { "keyword", "Spell" },
    { "string", "Note" },
    { "variable", "Item" },
  },

  words = {
    traveler = "Tarnished",
    hub = "Roundtable Hold",
    sites = "Sites of Grace",
    site = "Site of Grace",
    sites_found = "graces found",
    no_sites = "No graces yet. Scanning your realms…",
    rise = "press any key to rise",
    choose_region = "Choose Region",
    region_prompt = "Choose your region",
    phantom = "Phantom of %s",
    past_self = "Bloodstain of your past self",
    salute = "The Lands Between salute you",
    motion_on = "The Lands Between stir once more",
    motion_off = "The world stands still",
    map = "Map of the Lands Between",
  },
}
