-- What the command palette lists. Pure data plus the text each row shows, so it can be tested.
local M = {}

---@class PaletteEntry
---@field icon string
---@field name string
---@field desc string
---@field key? string the mapping that does the same, shown so it sticks
---@field cmd string ex command the entry runs

---@type PaletteEntry[]
M.ENTRIES = {
  {
    icon = "󰮫 ",
    name = "HUD",
    desc = "The inventory start screen",
    key = "<leader>uh",
    cmd = "Hud",
  },
  {
    icon = "󰊢 ",
    name = "Travel",
    desc = "Pick a repo and travel there",
    key = "<leader>fp",
    cmd = "Repos",
  },
  {
    icon = "󰝰 ",
    name = "Browse folders",
    desc = "Walk folders with hjkl",
    cmd = "BrowseFolders",
  },
  {
    icon = "▦ ",
    name = "Map",
    desc = "Folders as rooms, red with errors left",
    key = "<leader>fM",
    cmd = "Map",
  },
  {
    icon = "󰙨 ",
    name = "Trial",
    desc = "Run the whole test suite",
    key = "<leader>cT",
    cmd = "Trial",
  },
  {
    icon = "󰍉 ",
    name = "Review",
    desc = "Claude reviews a PR's diff",
    key = "<leader>pr",
    cmd = "Review",
  },
  {
    icon = "󰊠 ",
    name = "Phantom",
    desc = "Who wrote this line",
    key = "<leader>gw",
    cmd = "Phantom",
  },
  {
    icon = "✎ ",
    name = "Inscribe",
    desc = "Leave a message on this line",
    key = "<leader>mw",
    cmd = "Inscribe",
  },
  {
    icon = "✎ ",
    name = "Inscriptions",
    desc = "Every message left in this repo",
    key = "<leader>ml",
    cmd = "Inscriptions",
  },
  {
    icon = "󰄀 ",
    name = "Snapshot",
    desc = "The buffer as a PNG card",
    key = "<leader>cp",
    cmd = "Snapshot",
  },
  {
    icon = "󰏘 ",
    name = "Region",
    desc = "Choose today's region",
    key = "<leader>ut",
    cmd = "Region",
  },
  {
    icon = "󰯉 ",
    name = "Franchise",
    desc = "Choose today's world",
    key = "<leader>uf",
    cmd = "Franchise",
  },
  {
    icon = "󰂵 ",
    name = "Opacity",
    desc = "Terminal opacity, Kitty and Ghostty",
    key = "<leader>uo",
    cmd = "Opacity",
  },
  {
    icon = "󰎈 ",
    name = "Now playing",
    desc = "Cover, lyrics and controls",
    key = "<leader>o",
    cmd = 'lua require("core.music").open()',
  },
  {
    icon = "󰑮 ",
    name = "Lesson",
    desc = "Train with the coach",
    key = "<leader>kk",
    cmd = "Btb lesson",
  },
  {
    icon = "󰂺 ",
    name = "Lesson library",
    desc = "Every lesson fought so far",
    key = "<leader>kb",
    cmd = "Btb lessons",
  },
  { icon = "󰒲 ", name = "Rest", desc = "Rest now instead of after idling", cmd = "Rest" },
  { icon = "󰔟 ", name = "Title", desc = "The franchise title screen", cmd = "Title" },
  { icon = "󰛐 ", name = "Boss", desc = "Toggle boss fights", key = "<leader>uB", cmd = "Boss" },
  { icon = "󰖨 ", name = "Fog", desc = "Walk through a fog wall", cmd = "Fog" },
  {
    icon = "󰐊 ",
    name = "Motion",
    desc = "Toggle animations",
    key = "<leader>um",
    cmd = "Motion",
  },
  { icon = "󰕾 ", name = "Sound", desc = "Preview a sound", cmd = "Sound " },
  { icon = "󰀦 ", name = "Banner", desc = "Show a banner", cmd = "Banner " },
  { icon = "󰑓 ", name = "Rescan repos", desc = "Look for new repos now", cmd = "ReposRescan" },
}

---Whether an entry still needs arguments, so it goes to the command line instead of running.
---@param entry PaletteEntry
---@return boolean
function M.wants_args(entry)
  return entry.cmd:sub(-1) == " "
end

---The text the picker matches on: name, what it does and its key.
---@param entry PaletteEntry
---@return string
function M.search_text(entry)
  return table.concat({ entry.name, entry.desc, entry.key or "" }, " ")
end

return M
