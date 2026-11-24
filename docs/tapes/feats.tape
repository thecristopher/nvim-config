# Feats: the last two unlock on screen, then the showcase and the year card
Output images/demo/feats.gif
Source docs/tapes/settings.tape
Hide
Type `cd "$DEMO_REPO" && clear && DEMO_SEED=1 nvim --cmd "luafile $DEMO_LUA" lua/init.lua`
Enter
Sleep 2s
Show
Sleep 12s
Type ":Feats"
Enter
Sleep 4s
Type "q"
Type ":Wrapped 2026"
Enter
Sleep 5s
