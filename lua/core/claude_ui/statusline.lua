-- Claude Code's statusline command: reads the session JSON on stdin, gathers what the editor knows
-- (franchise and region colors) plus the branch and the song playing, and prints the rows.
-- ELDENTREE_CLAUDE_MUSIC=0 skips the song, ELDENTREE_CIDER_TOKEN carries Cider's API token.
local render = require("core.claude_ui.actions.statusline").render
local music = require("core.music.actions")

local M = {}

local function output(cmd)
  local ok, result = pcall(function()
    return vim.system(cmd, { text = true }):wait(1500)
  end)
  if not ok or result.code ~= 0 then
    return nil
  end
  return result.stdout
end

local function branch(dir)
  if not dir then
    return nil
  end
  local stdout = output({ "git", "-C", dir, "branch", "--show-current" })
  return stdout and vim.trim(stdout) or nil
end

local function cider_track()
  local token = vim.env.ELDENTREE_CIDER_TOKEN
  local playing = music.parse_cider_playing(output(music.cider_command("is-playing", "GET", token)))
  if playing == nil then
    return nil
  end
  return music.parse_cider_track(output(music.cider_command("now-playing", "GET", token)), playing)
end

local function song()
  if vim.env.ELDENTREE_CLAUDE_MUSIC == "0" then
    return nil
  end
  ---@type table|nil
  local track = cider_track()
  if not track and vim.fn.has("mac") == 1 then
    track = music.parse_music(output(music.music_status_command()))
  end
  return track and music.label(track, require("core.claude_ui.actions.statusline").SONG_WIDTH)
    or nil
end

--- Prints the statusline for the session JSON waiting on stdin.
---@param _root string repo root, unused: everything comes from the lua modules
---@param _args string[] command line arguments, unused
function M.run(_root, _args)
  local ok, data = pcall(vim.json.decode, io.read("*a") or "")
  data = ok and type(data) == "table" and data or {}
  local workspace = type(data.workspace) == "table" and data.workspace or {}
  local rows = render(data, {
    lore = require("core.franchise").current(),
    region = require("core.themes").current(),
    branch = branch(workspace.current_dir or data.cwd),
    song = song(),
  })
  io.write(table.concat(rows, "\n"), "\n")
end

return M
