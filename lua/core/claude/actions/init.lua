-- Finds the claude binary and builds its argv, kept pure so the Windows quirks can be tested anywhere.
local M = {}

M.DISALLOWED_TOOLS = "Bash Edit Write NotebookEdit Read Grep Glob Task WebFetch WebSearch Agent Artifact"

-- installers drop claude in these spots even when PATH never learned about them
function M.fallback_paths(home, appdata, is_windows)
  if is_windows then
    return {
      home .. "/.local/bin/claude.exe",
      appdata .. "/npm/claude.cmd",
      home .. "/.claude/local/claude.cmd",
    }
  end
  return {
    home .. "/.local/bin/claude",
    home .. "/.claude/local/claude",
  }
end

function M.resolve(override, on_path, fallbacks, is_executable)
  if override and override ~= "" then return override end
  if on_path and on_path ~= "" then return on_path end
  for _, path in ipairs(fallbacks) do
    if is_executable(path) then return path end
  end
  return nil
end

-- the prompt rides on stdin because cmd.exe cuts arguments at the first newline and caps them at 8k
function M.command(bin)
  return { bin, "-p", "--disallowedTools", M.DISALLOWED_TOOLS }
end

return M
