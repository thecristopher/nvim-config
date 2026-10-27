-- back-to-basics: drills forged by Claude, Eldentree celebrates the verdicts

local ROOT = vim.fn.expand("~/Documents/back-to-basics")

return {
  dir = ROOT,
  name = "back-to-basics",
  event = "VeryLazy",
  cond = function()
    return vim.uv.fs_stat(ROOT) ~= nil
  end,
  opts = {},
  config = function(_, opts)
    require("back-to-basics").setup(opts)
    -- died is left out on purpose: it crumbles and closes the window behind it, the solution included
    vim.api.nvim_create_autocmd("User", {
      pattern = "BtbResult",
      callback = function(event)
        if event.data.level_up then
          require("core.banner").show("great", { subtitle = "level " .. event.data.level_up })
        elseif event.data.ok then
          require("core.banner").show("felled", { subtitle = event.data.id })
        end
      end,
    })
    vim.api.nvim_create_autocmd("User", {
      pattern = "BtbFocus",
      callback = function()
        pcall(vim.cmd, "Copilot detach")
      end,
    })
  end,
}
