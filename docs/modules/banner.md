# Banners

`lua/core/banner/`: Elden Ring style banners (`:Banner felled|great|died|grace|cleansed`) fired by
commits, PRs, `:Trial`, new Sites of Grace, region changes and long fights with errors. `died`
crumbles the window behind it into cellular-automaton rain (`lua/plugins/fun.lua`) and closes it as
the banner fades, `vim.g.eldentree_rain = false` turns that off. A lore's `banner_styles` can pick a
`look`: `band` (default), `blackout` (RE's death, the screen sinks to black) or `clapper`
(Elizabeth's CUT!, a slate that snaps shut). `geometry` keeps subtitles below drips, and `:Banner
died` previews without a subtitle.
