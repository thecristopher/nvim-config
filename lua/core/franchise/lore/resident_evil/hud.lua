-- What the safe room calls everything on the HUD: the hub keys as the attaché case's items, the
-- plates over the case, every kind of item with its category and a line from the files, the records'
-- icons, the condition under the survivor and the ink ribbons on the typewriter.
return {
  -- every hub key: the name on the item banner, the short name in its cell, what it does and a line
  -- read from the files
  keys = {
    f = {
      name = "Search the Area",
      slot = "Search",
      desc = "Search every file of the facility by name.",
      flavor = "Leave no drawer unopened.",
    },
    g = {
      name = "Investigate",
      slot = "Inspect",
      desc = "Search every line of the facility for a pattern.",
      flavor = "Something is written here. Read it closely.",
    },
    r = {
      name = "Recent Pickups",
      slot = "Pickups",
      desc = "Reopen something you had in your hands recently.",
      flavor = "You remember holding this one.",
    },
    p = {
      name = "Safe Rooms",
      slot = "Safe Rooms",
      desc = "Travel to another safe room, its session comes back with you.",
      flavor = "The music changes. You're safe in here.",
    },
    e = {
      name = "Floor Plan",
      slot = "Floor Plan",
      desc = "Open the file tree beside the code.",
      flavor = "Know the layout before you open a door.",
    },
    o = {
      name = "Unexplored Area",
      slot = "Explore",
      desc = "Pick any folder on disk and set up there.",
      flavor = "No map for this place yet.",
    },
    n = {
      name = "Blank Report",
      slot = "Report",
      desc = "Start an empty buffer and write something new.",
      flavor = "Write it down before it gets you.",
    },
    s = {
      name = "Load Game",
      slot = "Load",
      desc = "Bring back the windows and buffers of your last visit here.",
      flavor = "Continue from your last save.",
    },
    t = {
      name = "Change Location",
      slot = "Location",
      desc = "Change the location, its colors and its survivor.",
      flavor = "Raccoon City isn't the only nightmare.",
    },
    c = {
      name = "Field Manual",
      slot = "Manual",
      desc = "Look inside this very config.",
      flavor = "Survival is all in the details.",
    },
    b = {
      name = "Shooting Range",
      slot = "Range",
      desc = "Face the day's drill with your partner.",
      flavor = "Accuracy first. Speed comes later.",
    },
    d = {
      name = "Briefing Room",
      slot = "Briefing",
      desc = "Open the desk, where tickets wait for orders.",
      flavor = "Hunnigan has new intel.",
    },
    L = {
      name = "Workbench",
      slot = "Workbench",
      desc = "Open lazy.nvim, where every plugin gets tuned up.",
      flavor = "A little firepower never hurt anyone.",
    },
    m = {
      name = "The Merchant",
      slot = "Merchant",
      desc = "Open Mason, where the language servers come from.",
      flavor = "What are ya buyin'?",
    },
    q = {
      name = "Quit Game",
      slot = "Quit",
      desc = "Close nvim.",
      flavor = "Leave the safe room behind.",
    },
    a = {
      name = "Facility Map",
      slot = "Map",
      desc = "See every room of the facility, red wherever work remains.",
      flavor = "Red rooms still hold something. Blue ones are clear.",
    },
  },

  -- the plates over the attaché case
  tabs = {
    item = "ITEM",
    keys = "KEYS",
    box = "BOX",
    file = "FILE",
    map = "MAP",
    exit = "EXIT",
  },

  -- every kind of item: its category on the banner and a line from the files
  kinds = {
    action = { name = "Equipment", flavor = "Standard issue. Keep it close." },
    recent = { name = "File", flavor = "A file you picked up recently." },
    branch = { name = "Key", flavor = "A key. It opens another path." },
    stash = { name = "Item Box", flavor = "Stored in the item box for later." },
    message = { name = "Memo", flavor = "A memo left for the next survivor." },
    region = { name = "Location", flavor = "Another location of the outbreak." },
    franchise = { name = "Scenario", flavor = "Somewhere else, another nightmare." },
    project = { name = "Safe Room", flavor = "A safe room. The typewriter is ready." },
    room = { name = "Room", flavor = "Part of the facility, cleared or not." },
    change = { name = "Evidence", flavor = "Something moved in here." },
    exit = { name = "Exit", flavor = "There's always a way out." },
    trophy = { name = "Record", flavor = "A record of your survival." },
    lesson = { name = "Training", flavor = "Notes from the shooting range." },
  },

  -- the records: enemies killed, the best rank, the days survived and the longest streak
  trophy_icons = {
    title = "󰔸",
    felled = "󰚌",
    rank = "󰔸",
    days = "󰃭",
    streak = "󰉁",
  },

  -- the condition under the survivor in STATUS and the ribbons on the typewriter
  stats = {
    fine = "FINE",
    caution = "CAUTION",
    danger = "DANGER",
    ribbons = "INK RIBBON",
  },
}
