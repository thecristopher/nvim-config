-- The repo's own spell word list: technical words and the franchises' names, so prose in either
-- language stops underlining statusline, Ghostty or Malenia. `zg` adds to the same versioned file,
-- and the compiled .spl, which git ignores, is rebuilt whenever the list is newer.
local actions = require("core.spell.actions")

local M = {}

M.WORDS = vim.fn.stdpath("config") .. "/spell/en.utf-8.add"

local function mtime(path)
  local stat = vim.uv.fs_stat(path)
  return stat and stat.mtime.sec or nil
end

--- Compiles the word list when it changed since the last build.
function M.build()
  if not actions.needs_build(mtime(M.WORDS), mtime(M.WORDS .. ".spl")) then
    return
  end
  pcall(vim.cmd, "silent mkspell! " .. vim.fn.fnameescape(M.WORDS))
end

function M.setup()
  vim.opt.spellfile = M.WORDS
  -- mkspell takes a few milliseconds, nothing needs it before the first prose buffer
  vim.schedule(M.build)
end

return M
