-- Markdown rendered in the buffer: carved headings, real checkboxes and framed code blocks

return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    opts = {
      heading = {
        sign = false,
        icons = { "◈ ", "◆ ", "◇ ", "· ", "· ", "· " },
      },
      bullet = { icons = { "◆", "◇", "•", "·" } },
      checkbox = {
        unchecked = { icon = "󰄱 " },
        checked = { icon = "󰄵 " },
      },
      code = { sign = false, width = "block", right_pad = 2 },
    },
  },
}
