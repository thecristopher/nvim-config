-- What the dressing room calls everything on the HUD: the hub keys as her vanity, the tags on the
-- rail, every kind of piece with its category and a line in her voice, the awards' icons and the
-- call sheet's labels.
return {
  -- every hub key: the name in the close up, the short name on the rack, what it does and a line in
  -- her voice
  keys = {
    f = {
      name = "Fitting",
      slot = "Fitting",
      desc = "Find any piece of the wardrobe by name.",
      flavor = "Every costume has its place on the rack.",
    },
    g = {
      name = "Read the Script",
      slot = "Script",
      desc = "Search every line of the show for a word.",
      flavor = "She knows every line. Do you?",
    },
    r = {
      name = "Last Looks",
      slot = "Last Looks",
      desc = "Reopen what you wore not long ago.",
      flavor = "One more look in the mirror before curtain.",
    },
    p = {
      name = "Stages",
      slot = "Stages",
      desc = "Move to another stage, its set comes back with you.",
      flavor = "Every stage has its own light.",
    },
    e = {
      name = "Backstage",
      slot = "Backstage",
      desc = "Open the file tree beside the code.",
      flavor = "Where all the magic is kept.",
    },
    o = {
      name = "New Venue",
      slot = "Venue",
      desc = "Pick any folder on disk and set the stage there.",
      flavor = "An empty theater, all hers for the night.",
    },
    n = {
      name = "New Costume",
      slot = "Costume",
      desc = "Start an empty buffer and write something new.",
      flavor = "Fresh fabric, not a single seam yet.",
    },
    s = {
      name = "From the Top",
      slot = "Reprise",
      desc = "Bring back the windows and buffers of your last rehearsal here.",
      flavor = "Places, everyone.",
    },
    t = {
      name = "Change Role",
      slot = "Roles",
      desc = "Change her role, its colors and its costume.",
      flavor = "Tonight she plays someone new.",
    },
    c = {
      name = "Production Notes",
      slot = "Notes",
      desc = "Look inside this very config.",
      flavor = "Every detail of the show, in her handwriting.",
    },
    b = {
      name = "Rehearsal",
      slot = "Rehearsal",
      desc = "Run the day's scene with your coach.",
      flavor = "Practice until the lines feel like hers.",
    },
    d = {
      name = "Director's Desk",
      slot = "Director",
      desc = "Open the desk, where tickets wait for notes.",
      flavor = "The director would like a word.",
    },
    L = {
      name = "Prop Shop",
      slot = "Prop Shop",
      desc = "Open lazy.nvim, where every plugin is crafted.",
      flavor = "Glue, glitter and good plugins.",
    },
    m = {
      name = "Costume Supply",
      slot = "Supply",
      desc = "Open Mason, where the language servers come from.",
      flavor = "Need a new look? They have it in your size.",
    },
    q = {
      name = "Lights Out",
      slot = "Lights Out",
      desc = "Close nvim.",
      flavor = "That's a wrap, love.",
    },
    a = {
      name = "Blocking Chart",
      slot = "Blocking",
      desc = "See every part of the set, red wherever work remains.",
      flavor = "Where everyone stands, and what's left to rehearse.",
    },
  },

  -- the tags hanging from the rail and their icons, the lessons tag takes coach.lessons and the
  -- last one trophies.title
  tabs = {
    tools = "Vanity",
    recent = "Recent Takes",
    keys = "Props",
    messages = "Notes",
    regions = "Roles",
  },
  tab_icons = {
    tools = "󱎵",
    recent = "󰋚",
    keys = "󰌆",
    messages = "󰋑",
    regions = "󰴂",
    lessons = "󰂺",
    trophies = "󰆥",
  },

  -- every kind of piece: its category on the close up and a line in her voice
  kinds = {
    action = { name = "Vanity", flavor = "Within reach of the mirror, always." },
    recent = { name = "Take", flavor = "A take she just did." },
    branch = { name = "Prop", flavor = "A prop that changes the whole scene." },
    stash = { name = "Trunk", flavor = "Packed in the trunk for the next show." },
    message = { name = "Note", flavor = "A note pinned to the mirror." },
    region = { name = "Role", flavor = "Another role, another costume." },
    franchise = { name = "Show", flavor = "A different show entirely." },
    project = { name = "Stage", flavor = "A stage, lit and waiting for her." },
    room = { name = "Set", flavor = "A part of the set, rehearsed or not." },
    change = { name = "Rewrite", flavor = "A change since the last rehearsal." },
    exit = { name = "Curtain", flavor = "The curtain falls, eventually." },
    trophy = { name = "Award", flavor = "One more for the shelf." },
    lesson = { name = "Script", flavor = "A script to rehearse." },
  },

  -- the awards: villains upstaged, the best review, the show days and the longest run
  trophy_icons = {
    title = "󰆥",
    felled = "󰴂",
    rank = "󰓎",
    days = "󰃭",
    streak = "󰋑",
  },

  -- the call sheet of the quest you left open
  stats = {
    scene = "SCENE",
    cast = "CAST",
    location = "LOCATION",
    call = "CALL",
  },

  -- lines the other worlds lent her, read now and then between her own
  guest_messages = {
    "What are you buying? A cleaner commit?",
    "Your inventory is full of TODOs, love",
    "Rest at grace, then refactor",
    "Let the rot bloom somewhere else",
  },
}
