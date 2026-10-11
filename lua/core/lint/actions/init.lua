-- Decides which linters can actually run, so a missing binary or a bare selene never floods the buffer.
local M = {}

-- without a selene.toml selene assumes plain Lua and calls every `vim` an error
M.NEEDS_CONFIG = {
  selene = { "selene.toml" },
}

function M.runnable(names, is_installed, has_config)
  return vim.tbl_filter(function(name)
    if not is_installed(name) then return false end
    local configs = M.NEEDS_CONFIG[name]
    return configs == nil or has_config(configs)
  end, names)
end

return M
