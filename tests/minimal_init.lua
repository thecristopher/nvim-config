-- Bare bones init for the test runner: just this repo and plenary, no plugins
local repo_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")

local function find_plenary()
  -- env var goes last because a nil first entry would stop ipairs cold
  local candidates = {
    vim.fn.stdpath("data") .. "/lazy/plenary.nvim",
    vim.fn.expand("~/.local/share/nvim/lazy/plenary.nvim"),
    vim.env.PLENARY_DIR,
  }
  for _, path in ipairs(candidates) do
    if path and vim.fn.isdirectory(path) == 1 then
      return path
    end
  end
  error("plenary.nvim not found. Open nvim once so lazy installs it, or set PLENARY_DIR.")
end

vim.opt.rtp:prepend(repo_root)
vim.opt.rtp:prepend(find_plenary())
vim.opt.swapfile = false
-- specs speak Elden Ring unless they switch franchise on purpose, so the day never changes a result
vim.g.eldentree_franchise = "elden_ring"
vim.cmd("runtime plugin/plenary.vim")
