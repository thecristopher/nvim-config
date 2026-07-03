-- Street Fighter combo display — toggle with <leader>uK

return {
  {
    -- Local module, no external package.
    -- lazy.nvim only wires the keymap; the module loads on first toggle.
    dir  = vim.fn.stdpath("config"),
    name = "sfcombo",
    lazy = true,
    keys = {
      {
        "<leader>uK",
        function() require("core.sfcombo").toggle() end,
        desc = "SF Combo toggle",
      },
    },
  },
}
