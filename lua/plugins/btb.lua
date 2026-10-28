-- back-to-basics: daily drills by hand, coached by the franchise's persona (Claire in Resident
-- Evil, Malenia in Elden Ring). <leader>kk starts the lesson, <leader>kb opens the lesson library.
-- vim.g.eldentree_btb_dir points at the clone when it is not in ~/Documents/GitHub/back-to-basics.

local dir = vim.g.eldentree_btb_dir or vim.fn.expand("~/Documents/GitHub/back-to-basics")

return {
  {
    dir = dir,
    name = "back-to-basics",
    cond = vim.fn.isdirectory(dir) == 1,
    event = "VeryLazy",
    opts = function()
      local bridge = require("core.btb")
      return {
        root = dir,
        persona = bridge.persona,
        portrait = bridge.portrait,
        sound = bridge.sound,
        progress = require("core.progress").start,
        -- the coach takes the stage once the solve's banner is done, never on top of it
        advance_ms = require("core.banner.actions").KINDS.felled.duration,
      }
    end,
    config = function(_, opts)
      require("back-to-basics").setup(opts)
      require("core.btb").setup()
    end,
  },
}
