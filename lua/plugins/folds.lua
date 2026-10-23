-- nvim-ufo: closed folds keep their syntax colors and tell you how many lines they hide

return {
  {
    "kevinhwang91/nvim-ufo",
    event        = { "BufReadPost", "BufNewFile" },
    dependencies = { "kevinhwang91/promise-async" },
    keys = {
      { "zR", function() require("ufo").openAllFolds() end,  desc = "Open all folds" },
      { "zM", function() require("ufo").closeAllFolds() end, desc = "Close all folds" },
      { "zK", function() require("ufo").peekFoldedLinesUnderCursor() end, desc = "Peek fold" },
    },
    opts = {
      provider_selector = function() return { "treesitter", "indent" } end,
      fold_virt_text_handler = function(virt_text, lnum, end_lnum, width, truncate)
        return require("core.folds.actions").fold_chunks(virt_text, end_lnum - lnum, width, truncate)
      end,
      preview = { win_config = { border = "rounded", winblend = 0 } },
    },
  },
}
