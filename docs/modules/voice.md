# Voice

`lua/core/voice/`: the region's character speaks in the dialogue box, titled with their name, when
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
HUD) with its words in the dialogue box, falling back to the written line when sound is off or nvim
is unfocused. A spoken line stays up until its voice is over, a cached clip or a
Fish Audio take still on its way alike (`on_done` through `core/sound`'s `speak`), then lingers
`LINGER_MS` and never leaves before `SHOWN_MIN_MS` (`linger` in its actions), with `SHOWN_MAX_MS`
as a cap for a voice that never says it ended. `SPOKEN` lists the moments only heard out loud (btb's lesson, solves in a row and a
failed submit from `solve_moment`, hint, boss appearing, rest, expedition, the first travel to a
repo, commit and PR drafting, `:Trial` starting, `:Review` asking Claude, the map, bestiary and
chronicle opening, a ground message written, the title screen), quiet without a clip, and
`say(moment, vars, { quiet = true })` leaves the words off screen where the moment already shows its
own.

Only one character speaks at a time. Each moment has a priority (`PRIORITY` in its actions:
`URGENT` for verdicts, bosses, a new PR and the lesson's solves, `ASIDE` for openings and drafts,
`NORMAL` for the rest), and `admit` decides what a new moment does while a voice is speaking: a
louder one cuts in, an aside stays quiet, anything else waits for the voice to end. One moment
waits at most (`enqueue` keeps the louder, or the newest), and it goes stale after `QUEUE_TTL_MS`.
A cut voice ending late never releases the queue, the voice speaking now owns it by id.

Every moment fills `{weekday}`, `{daypart}` and `{repo}` (`context` in its actions) under its own
holes. The lines said lately per moment live in `eldentree_voice_recent.json` in state
(`core/voice/recent.lua`, `RECENT_SIZE`), so a line comes back only after the others had their
turn, across restarts too. The written fallback of a moment in `MOMENTS` also reads every take of
the role's script and fresh ones as words (`written` in the studio's actions), so a new line can be
read when it cannot be heard. `:Voice last` shows what was said last and how.

The dialogue box (`core/voice/dialogue.lua`) is one float centered at the bottom, right above the
statusline, with the character's name on the skin's frame. Notifications keep the top right, so
what a character says and what the editor reports never share a stack. A new line replaces the one
on screen (`speak`), except a written line arriving while a voice speaks, which waits for it to
end (`write`). A written line stays `reading_ms` (`READ_MS_PER_CHAR`, never under `SHOWN_MIN_MS`), and `dialogue_place` in its actions sizes it
(`DIALOGUE_SHARE` of the editor at most, `DIALOGUE_MIN_WIDTH` at least, `DIALOGUE_GAP` rows above
the statusline). Commit and PR drafting, the commit landing and a new PR speak there too, and their
progress notification keeps only its own words. Malenia, Ranni, Maliketh, Claire, Leon and every one of Elizabeth's roles speak through the
studio (Triss borrows Shadowheart's voice, Elden Ring's Malenia shares the one Elizabeth's wears), their audio lives out of the repo.

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
- A moment plays a cached take at once. A share of them (`FRESH_CHANCE`) also voices a take nobody
  has heard yet in the background (`choose` returns it as the prefetch), so the next time it plays
  from the cache. Only a moment with nothing cached, or a take that names what just happened, waits
  on the network, and a take that arrives after `LATE_MS` stays cached without playing: its words
  leave written.
- A take already on its way to Fish Audio is never asked twice: the baker and every moment that
  wants it wait on the same request.
- Holes (`HOLES` in its actions) let a take say what really happened: `{branch}` read as words
  (`speakable_branch`), `{number}` and `{boss}`. `SHARED_HOLES` (`{weekday}`, `{daypart}`,
  `{repo}`) work at any moment. Every role has a third take at `pushed`, `pr_opened`,
  `boss_felled` and `morning` with one, and a spec keeps each hole on a moment that can fill it.
  Takes with holes are voiced when they happen and cached per text.
- A baker caches the role in use ahead of time with Drama 3, one take every 20 seconds while the
  budget allows. Once every take has audio, a writer asks Claude (headless, quiet) for fresh takes
  for the moments with the fewest, from the role's voice sheet in `docs/voices/` and the takes it
  already has, a few runs a day (`MAX_FRESH` kept per moment). Claude answers `CANDIDATES` lines
  per moment and the first that passes `actions/check.lua` joins: one leading direction, one known
  paired tag at most, closed, holes the moment can fill, `MAX_WORDS`, and no paraphrase of a take
  the role has or banned (`SIMILAR` word overlap). Past `MAX_FRESH`, the oldest take without audio
  leaves first, so paid audio stays.
- `:Voice ban` bans the take said last: it leaves the role and the library, its audio goes, and the
  writer is told to write nothing like it. Bans live in `banned.json` beside `lines.json`, travel
  with an export, survive `:Voice prune all` and stop an import from bringing the take back.
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
