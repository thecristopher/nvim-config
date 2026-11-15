-- What the command palette lists. Pure data plus the text each row shows, so it can be tested.
local M = {}

---@class PaletteEntry
---@field icon string
---@field name string
---@field desc string
---@field key? string the mapping that does the same, shown so it sticks
---@field cmd? string ex command the entry runs
---@field feed? string a mapping the entry presses instead of running a command

---@type PaletteEntry[]
M.ENTRIES = {
  {
    icon = "󰮫 ",
    name = "HUD",
    desc = "The inventory start screen",
    key = "<leader>jh",
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
    icon = "󰕰 ",
    name = "Map",
    desc = "Folders as rooms, red with errors left",
    key = "<leader>jm",
    cmd = "Map",
  },
  {
    icon = "󰙨 ",
    name = "Trial",
    desc = "Run the whole test suite",
    key = "<leader>TT",
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
    icon = "󰃭 ",
    name = "Desk",
    desc = "Open the manager desk artifact",
    key = "<leader>jd",
    cmd = "Desk",
  },
  {
    icon = "󰑮 ",
    name = "CI",
    desc = "Open the branch's CI run",
    key = "<leader>gi",
    cmd = "CI",
  },
  {
    icon = "󰍩 ",
    name = "Threads",
    desc = "Open review threads of the PR",
    key = "<leader>mc",
    cmd = "Threads",
  },
  {
    icon = "󰯈 ",
    name = "Bestiary",
    desc = "The foes felled in this repo",
    key = "<leader>jb",
    cmd = "Bestiary",
  },
  {
    icon = "󱎫 ",
    name = "Expedition",
    desc = "A quiet focus block with its own rank",
    key = "<leader>je",
    cmd = "Expedition",
  },
  {
    icon = "󰃭 ",
    name = "Chronicle",
    desc = "The weeks you fought, as a grid",
    key = "<leader>jc",
    cmd = "Chronicle",
  },
  {
    icon = "󰙅 ",
    name = "Concepts",
    desc = "back-to-basics concepts as a map",
    key = "<leader>kC",
    cmd = "BtbConcepts",
  },
  {
    icon = "󰊠 ",
    name = "Phantom",
    desc = "Who wrote this line",
    key = "<leader>gw",
    cmd = "Phantom",
  },
  {
    icon = "󰏫 ",
    name = "Inscribe",
    desc = "Leave a message on this line",
    key = "<leader>mw",
    cmd = "Inscribe",
  },
  {
    icon = "󰏫 ",
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
    key = "<leader>jr",
    cmd = "Region",
  },
  {
    icon = "󰯉 ",
    name = "Franchise",
    desc = "Choose today's world",
    key = "<leader>jf",
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
  {
    icon = "󱜸 ",
    name = "Claude fullscreen",
    desc = "Claude takes the whole editor, again to put the layout back",
    key = "<leader>aF",
    cmd = "ClaudeFullscreen",
  },
  {
    icon = "󰩨 ",
    name = "Resize",
    desc = "Move the current window's borders with hjkl",
    key = "<leader>sw",
    cmd = "Resize",
  },
  {
    icon = "󰕮 ",
    name = "Reset layout",
    desc = "Tree and Claude at their defaults, the rest equal",
    key = "<leader>se",
    cmd = "ResizeReset",
  },
  { icon = "󰔟 ", name = "Title", desc = "The franchise title screen", cmd = "Title" },
  { icon = "󰛐 ", name = "Boss", desc = "Toggle boss fights", key = "<leader>ub", cmd = "Boss" },
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
  return entry.cmd ~= nil and entry.cmd:sub(-1) == " "
end

local DEFAULT_ICON = "󰌌 "

---The curated entries plus a row for every leader binding they do not already show, so the
---palette reaches every key in the leader map.
---@param entries PaletteEntry[]
---@param bindings LeaderBinding[]
---@param group_of fun(key: string): LeaderGroup|nil
---@return PaletteEntry[]
function M.with_bindings(entries, bindings, group_of)
  local shown = {}
  for _, entry in ipairs(entries) do
    if entry.key then
      shown[entry.key] = true
    end
  end
  local all = vim.list_extend({}, entries)
  for _, binding in ipairs(bindings) do
    local lhs = "<leader>" .. binding.key
    local normal = binding.mode == nil or binding.mode == "n"
    if normal and binding.key ~= "<leader>" and not shown[lhs] then
      shown[lhs] = true
      local group = group_of(binding.key)
      local icon = binding.icon or (group and group.icon)
      table.insert(all, {
        icon = icon and (icon.icon .. " ") or DEFAULT_ICON,
        name = binding.desc,
        desc = group and group.name or "leader",
        key = lhs,
        feed = lhs,
      })
    end
  end
  return all
end

---The text the picker matches on: name, what it does and its key.
---@param entry PaletteEntry
---@return string
function M.search_text(entry)
  return table.concat({ entry.name, entry.desc, entry.key or "" }, " ")
end

-- the widest a column may grow, so one long description never pushes every key off screen
M.MAX_NAME = 22
M.MAX_DESC = 42

---How wide the name, description and key columns are, name and description capped.
---@param entries PaletteEntry[]
---@return { name: integer, desc: integer, key: integer }
function M.column_widths(entries)
  local widths = { name = 0, desc = 0, key = 0 }
  for _, entry in ipairs(entries) do
    widths.name = math.max(widths.name, vim.fn.strdisplaywidth(entry.name))
    widths.desc = math.max(widths.desc, vim.fn.strdisplaywidth(entry.desc))
    widths.key = math.max(widths.key, vim.fn.strdisplaywidth(entry.key or ""))
  end
  widths.name = math.min(widths.name, M.MAX_NAME)
  widths.desc = math.min(widths.desc, M.MAX_DESC)
  return widths
end

-- the icon, the gaps between columns and the picker's own frame around the rows
local ROW_CHROME = 2 + 2 + 2 + 6

---How wide the palette window has to be to show every column, never wider than the screen.
---@param widths { name: integer, desc: integer, key: integer }
---@param columns integer the editor's width
---@return integer
function M.window_width(widths, columns)
  return math.min(widths.name + widths.desc + widths.key + ROW_CHROME, columns - 4)
end

---Fits text to a column: cut with an ellipsis when too long, padded with spaces when short.
---@param text string
---@param width integer display cells
---@return string
function M.fit(text, width)
  local cells = vim.fn.strdisplaywidth(text)
  if cells <= width then
    return text .. (" "):rep(width - cells)
  end
  local cut = vim.fn.strcharpart(text, 0, width - 1)
  while vim.fn.strdisplaywidth(cut) > width - 1 do
    cut = vim.fn.strcharpart(cut, 0, vim.fn.strchars(cut) - 1)
  end
  return cut .. "…" .. (" "):rep(width - 1 - vim.fn.strdisplaywidth(cut))
end

return M
