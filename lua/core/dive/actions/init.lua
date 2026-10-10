-- The VS Code style "dive into code" bindings, as plain data so they are testable.
-- Terminals send modified F keys two ways: <S-F12> or the old shifted code <F24>.
local M = {}

M.bindings = {
  { keys = { "<F12>", "gd" },                    action = "definition",      desc = "Go to definition" },
  { keys = { "<M-F12>", "<F60>", "gp" },         action = "peek_definition", desc = "Peek definition" },
  { keys = { "<S-F12>", "<F24>", "gR" },         action = "peek_references", desc = "Peek references" },
  { keys = { "<C-F12>", "<F36>", "gP" },         action = "peek_implementations", desc = "Peek implementations" },
  { keys = { "gr" },                             action = "references",      desc = "References" },
  { keys = { "gI" },                             action = "implementation",  desc = "Go to implementation" },
  { keys = { "gy" },                             action = "type_definition", desc = "Go to type definition" },
  { keys = { "gD" },                             action = "declaration",     desc = "Go to declaration" },
  { keys = { "<F2>", "<leader>cr" },             action = "rename",          desc = "Rename symbol" },
  { keys = { "<C-LeftMouse>" },                  action = "definition_at_mouse", desc = "Go to definition" },
  { keys = { "K" },                              action = "hover",           desc = "Hover docs" },
  { keys = { "<leader>ca" },                     action = "code_action",     desc = "Code action", mode = { "n", "x" } },
}

-- flattens the table above into one entry per key, which is what keymap.set wants
function M.expand(bindings)
  local maps = {}
  for _, binding in ipairs(bindings) do
    for _, lhs in ipairs(binding.keys) do
      table.insert(maps, {
        lhs = lhs,
        action = binding.action,
        desc = binding.desc,
        mode = binding.mode or "n",
      })
    end
  end
  return maps
end

return M
