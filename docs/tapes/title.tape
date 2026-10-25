# The franchise title screen, shown once a day and on every switch
Output images/demo/title.gif
Source docs/tapes/settings.tape
Hide
Type `cd "$DEMO_REPO" && clear && DEMO_TITLE=1 nvim --cmd "luafile $DEMO_LUA"`
Enter
Sleep 300ms
Show
Sleep 7s
