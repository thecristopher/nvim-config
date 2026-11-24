# Voice

`lua/core/voice/`: the region's character speaks as a notification titled with their name when
`:Trial` passes or fails, CI finishes, a push lands or an unstaged boss falls
(`require("core.voice").say(moment, vars)`). Lines live per region and moment in the lore's
`voices.lua` (`{branch}`, `{boss}` holes), written from the voice sheets in `docs/voices/`.
`MOMENTS` in its actions is the list `:checkhealth` asks every region for, and `:Franchise new`
copies `template/voices.lua` too. A region without lines stays quiet, `vim.g.eldentree_voice =
false` silences all. `MOMENTS` also has `committed` ({branch}), `pr_opened` ({number}),
`region_arrived` (a region picked with an announce), `morning`, `conflicts_cleared` and `woke`
(waking from rest). `M.setup()` greets on the first nvim of the day (`eldentree_morning` in state).
A region's `spoken` in `voices.lua` maps moments to clips in `sounds/<franchise>/voices/<region>/`
(file name without extension to the words it says, brought in with `scripts/sounds.py --voice`), and
`say` plays one out loud on the voice channel of `core/sound` (`speak`, over the moments and the
HUD) with its words as the notification, falling back to the written line when sound is off or nvim
is unfocused. `SPOKEN` lists the moments only heard out loud (btb's lesson, solves in a row and a
failed submit from `solve_moment`, hint, boss appearing, rest, expedition, the first travel to a
repo, commit and PR drafting, `:Trial` starting, `:Review` asking Claude, the map, bestiary and
chronicle opening, a ground message written, the title screen), quiet without a clip, and
`say(moment, vars, { quiet = true })` leaves the words off screen where the moment already shows its
own. So far Claire in `raccoon_city` and Leon in `rpd` speak.
