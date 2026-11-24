# Back to basics

`lua/core/btb/` and `lua/plugins/btb.lua`: back-to-basics (the clone in
`~/Documents/GitHub/back-to-basics`, or `vim.g.eldentree_btb_dir`). The coach of the day is the
`character` of the day's region (`coach_of` in `core/btb/actions`): Claire, Malenia and Ada
(`PARTNERS`) by their own btb persona, anyone else handed to btb as `{ id, character, franchise }`
so it summons them once, without romance, and the stage draws the region's portrait for them. A lore
whose `coach` names `played_by` and a `bond` (Elizabeth's) makes the coach that person in the role
(`played_coach`, persona `elizabeth-<role>`), and btb summons them with the bond instead of the ally
rule: the role's personality leads every line and every exercise, the bond only slips through in a
small detail, and a changed bond makes btb summon them again. `coach.training` and `coach.lessons`
naming the hub key and the HUD tab. The stage draws the coach with `core/hud/portrait.lua` in its
own `btb` slot, coach moments reuse the HUD sounds (quiet while the coach talks, so a clip never
crosses her voice), and every `User BtbResult` fires `felled` on a
clean solve or `great` on a level up and pays the XP in runes (a redo pays nothing) without the
merchant's milestone visit. The plugin puts
failing tests on the solution as warnings (on the line the stack or traceback reached), `<leader>kd`
opens the solution beside the reference with Claude's review on the lines it names, a redo's winbar
races its ghost, and `<leader>kk` asks the recapped lessons' closing questions before the recap.
`before_hint` gets `M.before_hint` here, so each hint is sold at the franchise's shop (`coach.hint`,
`coach.buy`, `coach.leave`) in silence: a lesson belongs to the coach, so the merchant never
speaks inside one. A clean pass is the coach's to cheer (`solve_moment`), a second failed submit
only plays `hud_back`, and `User BtbHint` takes its XP out of the runes and has the coach say the
hint out loud. btb calls the sound hook (`on_sound`) once per moment wherever
its line shows, and the hook leaves `hint` to `User BtbHint` (`hook_plays`).
`<leader>kC` / `:BtbConcepts` draws the concepts from `btb status` as rooms (`coach.concepts`). `b`
on the HUD starts the lesson and its description reads what is left of the day (from `btb today`),
the lessons fought so far live in the FILE tab (RE) or their own tab (Elden Ring). The pass that
ends the day carries its summary in `BtbResult`, and the great banner closes it with a rank S to D.
`<leader>km` / `:BtbPath` draws every track as a chain of levels. The plugin itself gives the
solution a winbar (title, level, clock, hints, last test run, keys) and saving runs `btb test`,
which never counts an attempt; dropbar stays off those buffers. `<leader>kk` lesson, `<leader>kb`
library, the rest of `<leader>k` comes from the plugin.
