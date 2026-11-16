-- What the Roundtable Hold calls everything on the HUD: the hub keys as grace menu entries, the
-- tabs, every kind of item with its category and an italic line of lore, the remembrances' icons and
-- the attributes under the champion's plaque.
return {
  -- every hub key: the name in the description, the short name on its tile, what it does and a line
  -- of lore read in italics under it
  keys = {
    f = {
      name = "Seek the Realm",
      slot = "Seek",
      desc = "Search every file of this realm by name.",
      flavor = "Even a forgotten file leaves a trace for those who seek it.",
    },
    g = {
      name = "Divine Words",
      slot = "Divine",
      desc = "Search every line of the realm for a pattern.",
      flavor = "The words you seek were carved somewhere, Tarnished.",
    },
    r = {
      name = "Memories",
      slot = "Memories",
      desc = "Reopen what you held in your hands not long ago.",
      flavor = "Memories fade. The files they left behind do not.",
    },
    p = {
      name = "Sites of Grace",
      slot = "Graces",
      desc = "Travel to another realm, its session returns with you.",
      flavor = "Follow the guidance of grace, wherever it leads.",
    },
    e = {
      name = "Survey the Land",
      slot = "Survey",
      desc = "Open the file tree beside the code.",
      flavor = "Every path of the Lands Between, laid bare at once.",
    },
    o = {
      name = "Unknown Lands",
      slot = "Venture",
      desc = "Pick any folder on disk and make camp there.",
      flavor = "Some lands have no grace yet. Venture forth anyway.",
    },
    n = {
      name = "Inscribe",
      slot = "Inscribe",
      desc = "Start an empty buffer and write something new.",
      flavor = "A blank stone, waiting for its first message.",
    },
    s = {
      name = "Pass Time",
      slot = "Pass Time",
      desc = "Bring back the windows and buffers of your last visit here.",
      flavor = "Rest at grace, and the world returns as you left it.",
    },
    t = {
      name = "Wander the Lands",
      slot = "Wander",
      desc = "Change the region, its colors and its champion.",
      flavor = "Other skies wait beyond the fog.",
    },
    c = {
      name = "Sacred Rites",
      slot = "Rites",
      desc = "Look inside this very config.",
      flavor = "The laws of this world, written by your own hand.",
    },
    b = {
      name = "Training Grounds",
      slot = "Training",
      desc = "Face the day's drill with your coach.",
      flavor = "Strength is earned one swing at a time.",
    },
    d = {
      name = "Roundtable Council",
      slot = "Council",
      desc = "Open the desk, where tickets wait for a ruling.",
      flavor = "Gideon knows all. Well, almost all.",
    },
    L = {
      name = "Smithing Table",
      slot = "Smithing",
      desc = "Open lazy.nvim, where every plugin is forged.",
      flavor = "Each plugin a blade, kept sharp by the smith.",
    },
    m = {
      name = "Twin Maiden Husks",
      slot = "Maidens",
      desc = "Open Mason, where the language servers are traded.",
      flavor = "Servers for runes. A fair trade, they say.",
    },
    q = {
      name = "Depart",
      slot = "Depart",
      desc = "Close nvim.",
      flavor = "Even a Tarnished must lay down the sword for a while.",
    },
    a = {
      name = "Map Fragments",
      slot = "Map",
      desc = "See every area of the realm, red wherever work remains.",
      flavor = "Fragment by fragment, the land reveals itself.",
    },
  },

  -- the tabs over the inventory and their icons, the lessons tab takes coach.lessons and the last
  -- one trophies.title
  tabs = {
    tools = "Tools",
    recent = "Memories",
    keys = "Key Items",
    messages = "Messages",
    regions = "Regions",
  },
  tab_icons = {
    tools = "󱌣",
    recent = "󰋚",
    keys = "󰌆",
    messages = "󰏫",
    regions = "󰫢",
    lessons = "󰂺",
    trophies = "󰔸",
  },

  -- every kind of item: its category in the detail pane and the line of lore under its effect
  kinds = {
    action = { name = "Tool", flavor = "A tool of the Roundtable, worn smooth by many hands." },
    recent = { name = "Memory", flavor = "A memory of the Lands Between, still warm." },
    branch = { name = "Key Item", flavor = "A path that splits from the main road." },
    stash = { name = "Sealed Item", flavor = "Sealed away, waiting for the one who returns." },
    message = { name = "Message", flavor = "Left on the ground for the Tarnished to come." },
    region = { name = "Region", flavor = "A land of the Lands Between, watched by its champion." },
    franchise = { name = "Realm", flavor = "Another world, beyond the fog." },
    project = { name = "Site of Grace", flavor = "A Site of Grace, where every journey begins." },
    room = { name = "Area", flavor = "A corner of the realm, explored or not." },
    change = { name = "Altered", flavor = "Something here changed since grace last shone." },
    exit = { name = "Departure", flavor = "Every journey ends somewhere." },
    trophy = { name = "Remembrance", flavor = "A remembrance of battles long past." },
    lesson = { name = "Lesson", flavor = "A lesson learned at a cost." },
  },

  -- the remembrances: foes felled, the finest rank, the days fought and the longest streak
  trophy_icons = {
    title = "󰔸",
    felled = "󰓥",
    rank = "󰆥",
    days = "󰫢",
    streak = "󰈸",
  },

  -- the attributes under the champion's plaque, from what the run already counts
  stats = {
    level = "Level",
    runes = "Runes",
    vigor = "Vigor",
    mind = "Mind",
    endurance = "Endurance",
    arcane = "Arcane",
  },

  -- floats over the inventory for a moment when you use an item
  used = "Obtained",
}
