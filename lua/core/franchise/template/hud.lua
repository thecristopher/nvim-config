-- What __title__ calls everything on the HUD: the hub keys, the tabs, every kind of item with its
-- category and a line of flavor, the trophies' icons and the attributes under the plaque. The keys
-- follow skin.dashboard: "roundtable" and "wardrobe" read tabs, tab_icons and stats as written here,
-- "inventory" reads tabs { item, keys, box, file, map, exit } and stats { fine, caution, danger, ribbons },
-- and "wardrobe" reads stats { scene, cast, location, call }.
return {
  -- every hub key: the name in the description, the short name on its tile, what it does and a line
  -- of flavor under it
  keys = {
    f = { name = "Find File", slot = "Files", desc = "Search every file of the project by name." },
    g = {
      name = "Live Grep",
      slot = "Grep",
      desc = "Search every line of the project for a pattern.",
    },
    r = { name = "Recent Files", slot = "Recent", desc = "Reopen something you had open recently." },
    p = {
      name = "Checkpoints",
      slot = "Checkpoints",
      desc = "Travel to another project, its session comes back with you.",
    },
    e = { name = "Explorer", slot = "Explorer", desc = "Open the file tree beside the code." },
    o = { name = "Open Folder", slot = "Folder", desc = "Pick any folder on disk and work there." },
    n = { name = "New File", slot = "New", desc = "Start an empty buffer and write something new." },
    s = {
      name = "Restore Session",
      slot = "Session",
      desc = "Bring back the windows and buffers of your last visit here.",
    },
    t = { name = "Choose Region", slot = "Region", desc = "Change the region and its colors." },
    c = { name = "Config", slot = "Config", desc = "Look inside this very config." },
    b = { name = "Training", slot = "Training", desc = "Face the day's drill with your coach." },
    d = { name = "Desk", slot = "Desk", desc = "Open the desk, where tickets wait." },
    L = { name = "Lazy", slot = "Lazy", desc = "Open lazy.nvim, where every plugin lives." },
    m = {
      name = "Mason",
      slot = "Mason",
      desc = "Open Mason, where the language servers come from.",
    },
    q = { name = "Quit", slot = "Quit", desc = "Close nvim." },
    a = {
      name = "Project Map",
      slot = "Map",
      desc = "See every room of the project, red wherever work remains.",
    },
  },

  tabs = {
    tools = "Tools",
    recent = "Recent",
    keys = "Key Items",
    messages = "Messages",
    regions = "Regions",
  },
  tab_icons = {
    tools = "󱌣",
    recent = "󰋚",
    keys = "󰌆",
    messages = "󰏫",
    regions = "◈",
    lessons = "󰂺",
    trophies = "󰔸",
  },

  -- every kind of item: its category and an optional line of flavor
  kinds = {
    action = { name = "Tool" },
    recent = { name = "Recent file" },
    branch = { name = "Branch" },
    stash = { name = "Stash" },
    message = { name = "Message" },
    region = { name = "Region" },
    franchise = { name = "Franchise" },
    project = { name = "Project" },
    room = { name = "Room" },
    change = { name = "Change" },
    exit = { name = "Exit" },
    trophy = { name = "Trophy" },
    lesson = { name = "Lesson" },
  },

  trophy_icons = { title = "󰔸", felled = "󰓥", rank = "󰔸", days = "󰃭", streak = "󰈸" },

  stats = {
    level = "Level",
    runes = "Coins",
    vigor = "Saves",
    mind = "Servers",
    endurance = "Streak",
    arcane = "Fixes",
  },

  -- floats over the inventory for a moment when you use an item
  used = "Used",
}
