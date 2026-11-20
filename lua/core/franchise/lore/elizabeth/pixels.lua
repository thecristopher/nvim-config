-- Tiny 8 bit sprites each role pops when something happens, drawn by lua/core/pixel. Every frame
-- is a grid of pixels, two rows per editor cell, where "." is transparent and every other letter
-- names a slot of the role's palette in `colors`. `moments` says which sprite plays for which moment.
return {
  westview = {
    colors = { a = "yellow", r = "red", p = "pink", w = "text" },
    moments = { saved = "hex", felled = "tiara", great = "tiara" },
    sprites = {
      -- a spark of chaos magic that bursts into a hex and leaves its embers behind
      hex = {
        {
          "..........",
          "..........",
          "..........",
          "....aa....",
          "....aa....",
          "..........",
          "..........",
          "..........",
        },
        {
          "..........",
          "....r.....",
          "..r.aa.r..",
          "...aaaa...",
          "...aaaa...",
          "..r.aa.r..",
          ".....r....",
          "..........",
        },
        {
          "...r..r...",
          ".r..pp..r.",
          "...p..p...",
          "r.p.ww.p.r",
          "r.p.ww.p.r",
          "...p..p...",
          ".r..pp..r.",
          "...r..r...",
        },
        {
          "r........r",
          "..........",
          "....p.....",
          "..........",
          "..........",
          ".....p....",
          "..........",
          "r........r",
        },
      },
      -- her crown, with a glint running over it
      tiara = {
        {
          "....aa....",
          "...aaaa...",
          "a..a..a..a",
          "aa.a..a.aa",
          "aaaa..aaaa",
          ".aaa..aaa.",
          "..aaaaaa..",
          "...rrrr...",
        },
        {
          "....ww....",
          "...awwa...",
          "a..a..a..a",
          "aa.a..a.aa",
          "aaaa..aaaa",
          ".aaa..aaa.",
          "..aaaaaa..",
          "...rrrr...",
        },
        {
          "....aa....",
          "...aaaa...",
          "w..a..a..a",
          "aw.a..a.aa",
          "aaaw..aaaa",
          ".aaa..aaa.",
          "..aaaaaa..",
          "...rrrr...",
        },
        {
          "....aa....",
          "...aaaa...",
          "a..a..a..w",
          "aa.a..a.wa",
          "aaaa..waaa",
          ".aaa..aaa.",
          "..aaaaaa..",
          "...rrrr...",
        },
      },
    },
  },
}
