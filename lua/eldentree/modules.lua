-- The modules the Eldentree engine sets up, in the order they need each other, and the choice of
-- which ones a config wants. Pure logic only.
local M = {}

-- every other module reads the world, its skin and the animation clock, so these always run
M.REQUIRED = { "franchise", "skin", "motion" }

-- the setup order: franchise first since everything reads it, leader and later last since they
-- bind and queue what the others defined
M.ORDER = {
  "franchise",
  "skin",
  "chrome",
  "terminal",
  "title",
  "sound",
  "repos",
  "motion",
  "banner",
  "boss",
  "conflicts",
  "bestiary",
  "phantom",
  "zones",
  "snapshot",
  "hub",
  "voice",
  "drift",
  "pixel",
  "hud",
  "fog",
  "messages",
  "trial",
  "runes",
  "ecg",
  "heartbeat",
  "map",
  "results",
  "chronicle",
  "feats",
  "wrapped",
  "season",
  "expedition",
  "ci",
  "threads",
  "tree",
  "rest",
  "trace",
  "music",
  "links",
  "claude_ui",
  "claude_panel",
  "resize",
  "desk",
  "leader",
  "later",
}

local function set(list)
  local lookup = {}
  for _, name in ipairs(list or {}) do
    lookup[name] = true
  end
  return lookup
end

--- The modules to set up, in order: every one by default, only the ones named in `only`, never
--- the ones named in `skip`, and always the required ones.
---@param opts { only?: string[], skip?: string[] }|nil
---@return string[]
function M.selected(opts)
  opts = opts or {}
  local only = opts.only and set(opts.only) or nil
  local skip, required = set(opts.skip), set(M.REQUIRED)
  local chosen = {}
  for _, name in ipairs(M.ORDER) do
    local wanted = (not only or only[name]) and not skip[name]
    if required[name] or wanted then
      table.insert(chosen, name)
    end
  end
  return chosen
end

--- The names in a list that are not Eldentree modules, so a typo fails loudly.
---@param names string[]|nil
---@return string[]
function M.unknown(names)
  local known = set(M.ORDER)
  local unknown = {}
  for _, name in ipairs(names or {}) do
    if not known[name] then
      table.insert(unknown, name)
    end
  end
  return unknown
end

return M
