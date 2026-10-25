-- Claude Code hook command: plays the franchise sound for the event named in the first argument
-- (grace when Claude finishes, died when it fails, the fog wall or the door when it needs you).
-- ELDENTREE_CLAUDE_SOUND=0 keeps Claude Code quiet.
local actions = require("core.claude_ui.actions")
local sound = require("core.sound.actions")

local M = {}

--- Plays the sound for a hook event and returns right away, the player keeps going on its own.
---@param root string repo root, where sounds/ lives
---@param args string[] command line arguments, the event first
function M.run(root, args)
  if vim.env.ELDENTREE_CLAUDE_SOUND == "0" then
    return
  end
  local franchise = require("core.franchise")
  local event = actions.hook_sound(args[1] or "", franchise.mechanic("travel"))
  if not event then
    return
  end
  local folder = ("%s/sounds/%s"):format(root, franchise.name())
  local ok, files = pcall(vim.fn.readdir, folder)
  local file = ok and sound.pick(files, event, math.random) or nil
  if not file then
    return
  end
  local command = sound.command(folder .. "/" .. file, function(name)
    return vim.fn.executable(name) == 1
  end)
  if command then
    pcall(vim.system, command, { detach = true })
  end
end

return M
