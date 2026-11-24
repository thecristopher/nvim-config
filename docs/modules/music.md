# Music

`lua/core/music/`: what Cider (REST API on `localhost:10767`, any OS) or Apple Music (osascript on
macOS, the system media controls through Windows PowerShell on Windows, in `actions/windows.lua`) is
playing, in the statusline. `<leader>o` or a click on it opens the now playing panel
(`core/music/panel.lua`, layout in `actions/panel.lua`) with the album cover drawn by the HUD
portrait, the song, artist and album beside it over a two row equalizer and the progress bar, and
the lyrics from LRCLIB (`core/music/lyrics.lua`, timing in `actions/lyrics.lua`) between two
dividers, the sung line swept karaoke style and its neighbors fading with distance, `l` shows or
hides the lyrics (the panel shrinks without them), `j`/`k` scroll lyrics without timing. The bar,
dividers and sung marks come from `music` in the skin, the panel title and lyric messages from
`music` in the lore, `p` play/pause, `n` next, `b` previous. Covers are cached per album and lyrics
per song in `stdpath("cache")/eldentree/music`, `vim.g.eldentree_lyrics = false` starts with the
lyrics hidden, and hidden lyrics never ask LRCLIB. `:Music [playpause|next|previous]`. Cider is
asked first, polling stops while nvim is unfocused. `vim.g.eldentree_cider_token` when Cider's auth
is on, `vim.g.eldentree_music = false` turns it off. A new song tints the panel's accents and the
statusline's `EldenMusicLine` with its cover's dominant vivid color (`core/music/tint.lua`, logic in
`actions/tint.lua`, ImageMagick's colors kept per album as `cover_<hash>.tint.json`) and fires `User
EldentreeMusicChanged` (`require("core.music").now_playing()` returns `track, source`). Its notice
(titled `music.now_playing`) replaces itself in place and stays quiet for 10 s after startup and
while the panel or the HUD names the song. While the panel is closed and lyrics are shown the
statusline sings the synced line (`core/music/ticker.lua`, its timer runs only while a song plays),
which asks LRCLIB for every song while lyrics are shown. The panel refuses to open under `WIDTH + 4`
columns.
