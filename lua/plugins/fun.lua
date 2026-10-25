-- The playful corner, straight from ThePrimeagen's setup: a motion training game and the code
-- that crumbles into rain (core/banner drops it on YOU DIED too)

return {
  {
    "ThePrimeagen/vim-be-good",
    cmd = "VimBeGood",
  },
  {
    "Eandrju/cellular-automaton.nvim",
    cmd = "CellularAutomaton",
    keys = {
      { "<leader>ur", "<cmd>CellularAutomaton make_it_rain<cr>", desc = "Make it rain" },
    },
  },
}
