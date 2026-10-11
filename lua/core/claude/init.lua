-- Headless claude runner shared by the commit and PR drafters.
local actions = require("core.claude.actions")

local M = {}

local function find_bin()
  local home    = vim.fs.normalize(vim.uv.os_homedir() or "")
  local appdata = vim.fs.normalize(vim.env.APPDATA or "")
  return actions.resolve(
    vim.g.eldentree_claude_bin,
    vim.fn.exepath("claude"),
    actions.fallback_paths(home, appdata, vim.fn.has("win32") == 1),
    function(path) return vim.fn.executable(path) == 1 end
  )
end

-- cb always gets a vim.system style result, even when claude never started
function M.run(prompt, cb)
  local bin = find_bin()
  if not bin then
    return vim.schedule(function()
      cb({ code = -1, stdout = "", stderr = "claude not found. Add its folder to PATH or set vim.g.eldentree_claude_bin." })
    end)
  end

  local ok, err = pcall(vim.system, actions.command(bin), { text = true, stdin = prompt }, function(res)
    vim.schedule(function() cb(res) end)
  end)
  if not ok then
    vim.schedule(function() cb({ code = -1, stdout = "", stderr = tostring(err) }) end)
  end
end

return M
