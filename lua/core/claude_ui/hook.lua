-- Claude Code hook command: plays the franchise sound for the event named in the first argument
-- (grace when a long turn finishes, died when it fails, the fog wall or the door when it needs
-- you). UserPromptSubmit only stamps when the turn began. Stays quiet during an expedition, after
-- a short turn and on a burst of permission prompts. ELDENTREE_CLAUDE_SOUND=0 keeps it quiet.
local actions = require("core.claude_ui.actions")
local sound = require("core.sound.actions")

local M = {}

local function state_dir()
  local dir = vim.fn.stdpath("state") .. "/eldentree_claude"
  vim.fn.mkdir(dir, "p")
  return dir
end

local function read_stamp(file)
  local ok, lines = pcall(vim.fn.readfile, file, "", 1)
  return ok and actions.stamp(lines[1]) or nil
end

local function write_stamp(file, now)
  pcall(vim.fn.writefile, { tostring(now) }, file)
end

-- the hook's JSON arrives on stdin, only the session id is needed to tell turns apart
local function session_id()
  local ok, data = pcall(vim.json.decode, io.read("*a") or "")
  return ok and type(data) == "table" and data.session_id or nil
end

local function play(root, event)
  local franchise = require("core.franchise")
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

--- Plays the sound for a hook event and returns right away, the player keeps going on its own.
---@param root string repo root, where sounds/ lives
---@param args string[] command line arguments, the event first
function M.run(root, args)
  if vim.env.ELDENTREE_CLAUDE_SOUND == "0" then
    return
  end
  local hook = args[1] or ""
  local now = os.time()
  local dir = state_dir()
  local turn_file = ("%s/turn_%s"):format(dir, actions.session_file(session_id()))
  if hook == "UserPromptSubmit" then
    return write_stamp(turn_file, now)
  end
  local permission_file = dir .. "/permission"
  local ctx = {
    now = now,
    turn_started = read_stamp(turn_file),
    last_permission = read_stamp(permission_file),
    expedition_until = read_stamp(vim.fn.stdpath("state") .. "/eldentree_expedition"),
  }
  if hook == "Stop" or hook == "StopFailure" then
    pcall(vim.fn.delete, turn_file)
  end
  local event = actions.hook_sound(hook, require("core.franchise").mechanic("travel"))
  if not event or not actions.should_play(hook, ctx) then
    return
  end
  if hook == "PermissionRequest" then
    write_stamp(permission_file, now)
  end
  play(root, event)
end

return M
