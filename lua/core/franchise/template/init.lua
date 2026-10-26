-- __title__: everything the config says and shows while it lives in this world.
-- Made by :Franchise new. Fill every list, then run :checkhealth eldentree to see what is left.
return {
  name = "__name__",
  title = "__title__",

  regions = require("core.franchise.lore.__name__.regions"),
  skin = require("core.franchise.lore.__name__.skin"),

  -- which version of each mechanic this world plays
  mechanics = {
    travel = "fog", -- "fog" or "door"
    boss = "duel", -- "duel" (health bar) or "stalker" (walks toward you)
    status = "grace", -- "grace" (breathing glyph) or "ecg" (Fine, Caution, Danger)
    rest = "embers", -- "embers" or "typewriter"
    ranking = false, -- true shows the last run's rank on the hub
  },

  currency = { glyph = "◈", stain = "󰈸" },

  -- Claude Code's statusline: context left, the 5 hour limit and the weekly one, plus spinner verbs
  claude = {
    bars = { context = "HP", five_hour = "MP", seven_day = "ST" },
    verbs = { "Exploring __title__" },
  },

  -- the now playing panel's title and what its lyrics say while they are not there
  music = {
    title = "Now playing",
    loading = "Looking for the lyrics…",
    missing = "No lyrics for this one",
    instrumental = "Instrumental",
  },

  -- who guards each region, one per region name
  bosses = {
    first_region = "The First Boss",
  },

  -- one per region name: glyphs, drift (rise, fall or float), speed in rows per second, palette slots
  weather = {
    first_region = {
      glyphs = { "·", "∙", "•" },
      drift = "rise",
      speed = { 1.6, 4.0 },
      from = "peach",
      to = "yellow",
    },
  },

  banners = {
    felled = "ENEMY FELLED",
    great = "GREAT ENEMY FELLED",
    died = "YOU DIED",
    grace = "CHECKPOINT REACHED",
    cleansed = "AREA CLEARED",
  },

  hub_messages = {
    "Write the first message of __title__ here",
  },

  message_templates = {
    "Try %s",
    "Be wary of %s",
  },

  landmarks = {
    tests = "The Proving Grounds",
  },

  places = {
    "The First Place",
  },

  item_categories = {
    { "function", "Skill" },
    { "type", "Relic" },
    { "string", "Note" },
    { "variable", "Item" },
  },

  words = {
    traveler = "Traveler",
    hub = "Hub",
    sites = "Checkpoints",
    site = "Checkpoint",
    sites_found = "checkpoints found",
    no_sites = "No checkpoints yet. Scanning…",
    rise = "press any key to continue",
    choose_region = "Choose Region",
    region_prompt = "Choose your region",
    phantom = "Echo of %s",
    past_self = "Your past self",
    salute = "__title__ salutes you",
    motion_on = "The world moves again",
    motion_off = "The world stands still",
    map = "Map",
  },
}
