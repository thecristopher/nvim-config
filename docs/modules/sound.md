# Sound

`lua/core/sound/`: plays `sounds/<franchise>/<event>.{wav,mp3,aiff,m4a,ogg}` (variants as
`event_2.wav`) for title, door, fog, curtain, rest, boss, merchant, phantom, continue (opening a
repo visited before), summon, comfort, bought, welcome, weapon, expedition, the HUD's `hud_open`,
`hud_close`, `hud_move`, `hud_select`, `hud_back`, `hud_tab`, `hud_page`, `hud_menu`, `hud_use`,
`hud_check`, `hud_combine` (each new HUD one falls back to the older one it refines through
`play_first`), the desk's `save` (every real file written), `yank` (a `y` or a yanky put), `typing`
(a ground message written), `undo`, the git keys' `branch`, `pulled`, `pushed`, `stash`, `unstash`,
`accessing` (every headless Claude run) and `accessed` (when it ends), `map`, `files` (the chronicle
and the bestiary) and every banner kind, `vim.g.eldentree_sound = false`, `:Sound <event>` previews.
Some files are clips from the games, the rest are built by `scripts/sounds.py` (stdlib synthesis and
ffmpeg), a recipe per event in its `RECIPES` table. A recipe may return a third value to finish it
its own way (`FINISH`: the echo tail, the loudness, a gain and trimming the silence at the end):
sounds that follow every keypress are built dry, short and quieter (`UI`), and every Elizabeth sound
is trimmed so none rings past its moment (`FRANCHISE_FINISH`). All of hers are synthesized, timed to
what they play under: the curtain to its 2.6 s animation, the title to the title screen, the rest
lullaby long enough to nap to. The game clips are listed in `CLIPS` and finished by `--clips`
(silence trimmed at both ends, a fade where one runs past its moment's `max`, evened out to the
loudness the built sounds share, HUD clips left quieter), and `--import SOURCE FRANCHISE EVENT`
brings a new clip in finished the same way. Every event a franchise plays has a file: Elden Ring
builds its HUD, comfort and expedition sounds, Resident Evil only its boss (its region is the
character select, its zone a key and great too, cleansed a herb and felled too, accessing the radio
and accessed the radio clicking off, and its typewriter save is composed by `--typewriter` from the
carriage and a run of keystrokes, `TYPEWRITER_KEYS`), and Resident Evil has a file for every event
but the other worlds' travels (`tests/core/sound_actions_spec.lua` checks it), its newer ones cut
from the HD Remaster's UI sounds. Sounds travel on two channels: the HUD's (each one cuts the last,
no buzz) and the moments' (`WEIGHT` in its actions: a heavier moment cuts a lighter one, a lighter
one stays quiet). On macOS sounds play through a resident player (`core/sound/player.swift`,
compiled by `swiftc` into `stdpath("cache")/eldentree/sound_player` whenever its source is newer,
run by `core/sound/player.lua`): an `AVAudioEngine` that stays running with every file decoded once,
since afplay took a second to wake the audio device on every sound and the HUD channel cut most of
them before they were heard. afplay, paplay or ffplay are the fallback until it is built or where it
cannot be. A spoken line fires `User EldentreeVoiceStarted` when it starts and `EldentreeVoiceEnded` when it is over, which `core/music` follows to lower the music under it. Nothing plays while nvim is unfocused except a `:Sound` preview (a key pressed in nvim
brings the focus back, since a terminal inside it can swallow the focus events), and a sound never
repeats the variant it played last. `scripts/sounds.py` builds `VARIANTS` of the frequent sounds
(`--variants`), and `CLIPS` may tame a clip's `peak`.
