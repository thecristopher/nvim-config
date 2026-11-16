-- The leader map in one place: every group, every key Eldentree binds itself and the checks that
-- keep it whole (no key bound twice, no key that makes another wait for the timeout).
local M = {}

---@class LeaderGroup
---@field prefix string keys after <leader> that open the group
---@field name string what which-key calls it
---@field icon? { icon: string, color: string }
---@field owner? "plugins" every key in it comes from a lazy spec, not from BINDINGS

---@type LeaderGroup[]
M.GROUPS = {
  { prefix = "a", name = "claude", icon = { icon = "󰚩", color = "orange" }, owner = "plugins" },
  { prefix = "b", name = "buffer", icon = { icon = "󰓩", color = "cyan" } },
  { prefix = "c", name = "code", icon = { icon = "󰅩", color = "orange" } },
  { prefix = "D", name = "debug", icon = { icon = "󰃤", color = "red" }, owner = "plugins" },
  { prefix = "f", name = "find", icon = { icon = "󰍉", color = "green" } },
  { prefix = "g", name = "git", icon = { icon = "󰊢", color = "orange" } },
  { prefix = "gh", name = "hunks", icon = { icon = "󰊢", color = "yellow" }, owner = "plugins" },
  {
    prefix = "h",
    name = "harpoon (1-4 jump)",
    icon = { icon = "󱡀", color = "cyan" },
    owner = "plugins",
  },
  { prefix = "j", name = "journey", icon = { icon = "󰮫", color = "yellow" } },
  {
    prefix = "k",
    name = "back to basics",
    icon = { icon = "󰓥", color = "red" },
    owner = "plugins",
  },
  { prefix = "m", name = "messages and threads", icon = { icon = "󰏫", color = "orange" } },
  {
    prefix = "M",
    name = "multicursor",
    icon = { icon = "󰇀", color = "yellow" },
    owner = "plugins",
  },
  {
    prefix = "p",
    name = "pull requests",
    icon = { icon = "󰘧", color = "purple" },
    owner = "plugins",
  },
  { prefix = "s", name = "windows", icon = { icon = "󱂬", color = "blue" } },
  { prefix = "S", name = "sessions", icon = { icon = "󰆓", color = "azure" }, owner = "plugins" },
  { prefix = "t", name = "terminal", icon = { icon = "󰆍", color = "red" } },
  { prefix = "T", name = "tests", icon = { icon = "󰙨", color = "green" } },
  { prefix = "u", name = "toggles", icon = { icon = "󰔡", color = "cyan" } },
  {
    prefix = "x",
    name = "diagnostics",
    icon = { icon = "󱖫", color = "green" },
    owner = "plugins",
  },
}

---@class LeaderBinding
---@field key string keys after <leader>
---@field desc string
---@field mode? string|string[] defaults to normal
---@field icon? { icon: string, color: string }
---@field call? string "module:function" to require and run
---@field cmd? string ex command to run
---@field handler? string name of a handler in core/leader that needs more than one call
---@field toggle? string a snacks toggle: "option:<name>" or a snacks toggle like "diagnostics"

---@type LeaderBinding[]
M.BINDINGS = {
  -- one key, the moves made a hundred times a day
  { key = "<leader>", desc = "Command palette", call = "core.palette:open" },
  { key = "w", desc = "Save", cmd = "write" },
  { key = "W", desc = "Save all", cmd = "wall" },
  { key = "q", desc = "Quit", cmd = "quit" },
  { key = "Q", desc = "Force quit all", cmd = "qall!" },
  {
    key = "o",
    desc = "Now playing",
    call = "core.music:open",
    icon = { icon = "󰎈", color = "purple" },
  },

  -- buffers
  { key = "bd", desc = "Delete buffer", handler = "buffer_delete" },
  { key = "bo", desc = "Delete other buffers", handler = "buffer_delete_others" },
  { key = "bD", desc = "Delete all buffers", cmd = "%bdelete|e#" },

  -- code
  { key = "cx", desc = "Make this file executable", handler = "make_executable" },
  { key = "cp", desc = "Snapshot the buffer as a PNG", cmd = "Snapshot" },
  {
    key = "cp",
    mode = "x",
    desc = "Snapshot the selection as a PNG",
    handler = "snapshot_selection",
  },
  {
    key = "cw",
    desc = "Replace the word under the cursor in this file",
    handler = "replace_word",
    icon = { icon = "󰛔", color = "cyan" },
  },

  -- find
  { key = "fp", desc = "Find repository", call = "core.repos:pick" },
  { key = "fu", desc = "Undo history", handler = "undo_history" },

  -- git, the quick keys come from core/git's QUICK_KEYS
  {
    key = "gw",
    desc = "Who wrote this (phantom)",
    call = "core.phantom:show",
    icon = { icon = "󰊠", color = "blue" },
  },
  { key = "gi", desc = "Open the CI run", call = "core.ci:open" },

  -- journey: the world's own screens and the look of the day
  { key = "jh", desc = "Inventory HUD", call = "core.hud:open" },
  { key = "jm", desc = "Project map", call = "core.map:open" },
  { key = "jb", desc = "Bestiary", call = "core.bestiary:open" },
  { key = "jc", desc = "Chronicle", call = "core.chronicle:open" },
  { key = "je", desc = "Expedition (focus block)", call = "core.expedition:start" },
  { key = "jd", desc = "Open the desk", call = "core.desk:open" },
  { key = "jf", desc = "Choose today's franchise", call = "core.franchise:pick" },
  { key = "jr", desc = "Choose region theme", call = "core.themes:pick" },
  { key = "jR", desc = "Next region theme", call = "core.themes:cycle" },
  { key = "jt", desc = "Title screen", call = "core.title:show" },

  -- messages on the ground and PR review threads
  { key = "mw", desc = "Write message", call = "core.messages:write" },
  { key = "md", desc = "Erase message", call = "core.messages:erase" },
  { key = "ml", desc = "List messages", call = "core.messages:pick" },
  { key = "mc", desc = "PR review threads", call = "core.threads:pick" },
  { key = "mo", desc = "Open the thread on this line", call = "core.threads:open" },
  { key = "mr", desc = "Resolve the thread on this line", call = "core.threads:resolve" },

  -- windows
  { key = "sv", desc = "Split vertical", cmd = "vsplit" },
  { key = "sh", desc = "Split horizontal", cmd = "split" },
  { key = "sc", desc = "Close window", cmd = "close" },
  { key = "so", desc = "Close the other windows", cmd = "only" },
  { key = "se", desc = "Reset window layout", call = "core.resize:reset" },
  { key = "sw", desc = "Resize windows", call = "core.resize:mode" },
  { key = "sz", desc = "Zoom window", handler = "zoom" },

  -- terminal
  { key = "to", desc = "Open the last link a terminal printed", call = "core.links:open_last" },

  -- tests, the whole suite verdict next to neotest's single runs
  { key = "TT", desc = "Trial: run the whole suite", call = "core.trial:run" },

  -- toggles
  { key = "um", desc = "Animations", call = "core.motion:toggle" },
  { key = "uf", desc = "Fog walls", handler = "toggle_fog" },
  { key = "ub", desc = "Boss fights", call = "core.boss:toggle" },
  { key = "uR", desc = "Auto root", handler = "toggle_autoroot" },
  { key = "uo", desc = "Terminal opacity", call = "core.terminal:pick_opacity" },
  { key = "un", desc = "Dismiss notifications", handler = "notifications_hide" },
  { key = "uN", desc = "Notification history", handler = "notifications_history" },
  { key = "uw", desc = "Wrap", toggle = "option:wrap" },
  { key = "us", desc = "Spell", toggle = "option:spell" },
  { key = "uL", desc = "Relative numbers", toggle = "option:relativenumber" },
  { key = "ud", desc = "Diagnostics", toggle = "diagnostics" },
  { key = "ui", desc = "Inlay hints", toggle = "inlay_hints" },
}

--- The left hand side of a binding, as vim.keymap.set takes it.
---@param key string keys after <leader>
---@return string
function M.lhs(key)
  return "<leader>" .. key
end

--- Splits a "module:function" call into its parts.
---@param call string
---@return string module, string fn
function M.parse_call(call)
  local module, fn = call:match("^([%w_.]+):([%w_]+)$")
  return module, fn
end

--- How a binding runs, so a binding with two ways (or none) is caught.
---@param binding LeaderBinding
---@return string[] kinds among call, cmd, handler and toggle
function M.kinds(binding)
  local kinds = {}
  for _, kind in ipairs({ "call", "cmd", "handler", "toggle" }) do
    if binding[kind] then
      table.insert(kinds, kind)
    end
  end
  return kinds
end

local function modes_of(binding)
  local mode = binding.mode or "n"
  return type(mode) == "table" and mode or { mode }
end

--- Every key bound more than once in the same mode.
---@param bindings LeaderBinding[]
---@return string[] "mode key" for each repeat
function M.duplicates(bindings)
  local seen, repeats = {}, {}
  for _, binding in ipairs(bindings) do
    for _, mode in ipairs(modes_of(binding)) do
      local id = mode .. " " .. binding.key
      if seen[id] then
        table.insert(repeats, id)
      end
      seen[id] = true
    end
  end
  return repeats
end

--- Keys that are the start of a longer key, which makes nvim wait timeoutlen before running them.
---@param keys string[]
---@return string[] "short < long" for each pair
function M.waits(keys)
  local pairs_found = {}
  for _, short in ipairs(keys) do
    for _, long in ipairs(keys) do
      if #long > #short and long:sub(1, #short) == short then
        table.insert(pairs_found, short .. " < " .. long)
      end
    end
  end
  return pairs_found
end

--- The group a key belongs to, the longest prefix that matches.
---@param key string keys after <leader>
---@return LeaderGroup|nil
function M.group_of(key)
  local found
  for _, group in ipairs(M.GROUPS) do
    local fits = #key > #group.prefix and key:sub(1, #group.prefix) == group.prefix
    if fits and (not found or #group.prefix > #found.prefix) then
      found = group
    end
  end
  return found
end

--- Whether a full mapping like "<leader>jh" is one Eldentree binds or one a plugin group owns.
---@param lhs string
---@return boolean
function M.knows(lhs)
  local key = lhs:match("^<leader>(.+)$")
  if not key then
    return false
  end
  for _, binding in ipairs(M.BINDINGS) do
    if binding.key == key then
      return true
    end
  end
  local group = M.group_of(key)
  return group ~= nil and group.owner == "plugins"
end

--- The which-key spec: every group with its icon, plus the icons single bindings carry.
---@param extra_icons? table<string, { icon: string, color: string }> keys bound elsewhere
---@return table[]
function M.which_key_spec(extra_icons)
  local spec = {}
  for _, group in ipairs(M.GROUPS) do
    table.insert(spec, { M.lhs(group.prefix), group = group.name, icon = group.icon })
  end
  for _, binding in ipairs(M.BINDINGS) do
    if binding.icon then
      table.insert(spec, { M.lhs(binding.key), icon = binding.icon })
    end
  end
  for key, icon in pairs(extra_icons or {}) do
    table.insert(spec, { M.lhs(key), icon = icon })
  end
  return spec
end

return M
