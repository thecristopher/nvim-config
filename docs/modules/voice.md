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
own. Claire, Leon and every one of Elizabeth's roles speak through the studio (Triss borrows
Shadowheart's voice), their audio lives out of the repo.

## Studio

`lua/core/voice/studio/`: a role cast with a Fish Audio voice speaks its takes out loud. The takes
live in each lore's `script.lua`, two per moment written with Drama 3 direction (`[how it is said]`
before the words, `<emphasis>`, `<whisper>`, `<soft>`, `<slow>`, `[break]`), and `voice` is the Fish
Audio voice id the role is cast with. A role without `voice` stays written, and `say` falls back to
the recorded clips and the written lines whenever the studio has nothing to play.

- A script take recorded by hand in the repo (`sounds/<franchise>/voices/<region>/`, the first take
  as `<moment>`, the second as `<moment>_2`, `clip_name` in its actions) counts as voiced: it plays
  first and is never baked again. Clips made by hand in the Fish Audio app can also go straight into
  the cache under their take's name (`store.path(voice, "drama-3", take)`), the way Claire's 64 did.
- A moment plays a cached take at once. A share of them (`FRESH_CHANCE`) voices a take nobody has
  heard yet, so new lines keep coming without every moment waiting on the network.
- Holes (`HOLES` in its actions) let a take say what really happened: `{branch}` read as words
  (`speakable_branch`), `{number}` and `{boss}`. Those are voiced on the spot and cached per text.
- A baker caches the role in use ahead of time with Drama 3, one take every 20 seconds while the
  budget allows. Once every take has audio, a writer asks Claude (headless, quiet) for fresh takes
  for the moments with the fewest, from the role's voice sheet in `docs/voices/` and the takes it
  already has, a few runs a day (`MAX_FRESH` kept per moment).
- Money: Drama 3 while the day's spend stays under `vim.g.eldentree_studio_daily` (0.50) and the
  balance above `vim.g.eldentree_studio_floor` (0.50), the free model (`s2.1-pro-free`) after that
  or when Fish Audio answers 402. The ledger lives in `eldentree_studio.json` in state, and the
  prepaid balance is the hard cap.
- Audio and fresh takes live in `stdpath("data")/eldentree/voices`, out of the repo:
  `<voice id>/<model>-<hash>-<length>.mp3` at 64 kbps, and `lines.json` for the fresh takes.
- The key comes from `FISH_API_KEY` or `~/.config/fish-audio/key`
  (`vim.g.eldentree_fish_key_file`).
- `:Voice status` shows the mode, the money and how much of the role is voiced. `:Voice local`
  never calls Fish Audio again and plays only what is cached, `:Voice live` brings it back.
  `:Voice write` asks Claude for fresh takes now. `:Voice prune` deletes free takes that have a paid
  version and takes no role says anymore once they are a month old (it also runs once a day on its
  own), `:Voice prune all` empties the cache and leaves the recorded clips alone. `:Voice export [file]` packs the audio and fresh
  takes into a `.tar.gz` (the desktop by default), `:Voice import <file>` adds one without
  overwriting what is cached. That is how the voices reach another machine, Windows included
  (`tar` and `curl` ship with Windows 10 and later, the cache lands in its own
  `stdpath("data")`). `vim.g.eldentree_studio = false` turns the studio off.
