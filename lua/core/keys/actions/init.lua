-- Spots global terminal mode mappings that would eat keystrokes meant for the shell or Claude.
local M = {}

local LEADERS = { "<leader>", "<localleader>", "<space>" }

-- <C-\> starts <C-\><C-n>, the one sequence that leaves any terminal
local ESCAPE_PREFIXES = { "<c-\\>", "<c-bslash>" }

local function starts_with_any(text, prefixes)
  for _, prefix in ipairs(prefixes) do
    if text:sub(1, #prefix) == prefix then return true end
  end
  return false
end

function M.steals_terminal_typing(lhs)
  local key = lhs:lower()
  if starts_with_any(key, LEADERS) or starts_with_any(key, ESCAPE_PREFIXES) then return true end
  -- anything else in angle brackets is a chord or special key nobody types into a prompt
  return key:sub(1, 1) ~= "<"
end

function M.has_terminal_mode(spec_key)
  local mode = spec_key.mode or "n"
  if type(mode) == "string" then return mode == "t" end
  return vim.tbl_contains(mode, "t")
end

-- every lazy key spec in a plugin spec list that maps terminal mode and steals typing
function M.terminal_thieves(plugin_specs)
  local found = {}
  for _, plugin in ipairs(plugin_specs) do
    for _, spec_key in ipairs(type(plugin.keys) == "table" and plugin.keys or {}) do
      if type(spec_key) == "table" and M.has_terminal_mode(spec_key) and M.steals_terminal_typing(spec_key[1]) then
        found[#found + 1] = spec_key[1]
      end
    end
  end
  return found
end

return M
