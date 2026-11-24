# Claude UI

`lua/core/claude_ui/` and `claude/`: Claude Code in the franchise. nvim rewrites
`~/.claude/themes/eldentree.json` from the palette on `EldentreeRegionSettled` and
`EldentreeFranchise`. `claude/*.lua` are tiny `nvim -l` entry points (they add the repo's `lua/` to
the path, since `-l` skips the user config) for the statusline, the sound hook, the banner words and
the installer, each calling `core.claude_ui.<name>.run`. `claude/install.lua` merges them into
`~/.claude/settings.json`, replacing only its own hooks and keeping the first backup. Bar labels and
spinner verbs live in each lore's `claude` table (`:checkhealth` requires it), and a region may add
its own `claude` (`bars` instead of the lore's, `verbs` after the lore's), so the spinner and the
bars speak of the character in use: every Elizabeth role has one. nvim rewrites only `spinnerVerbs`
in settings.json on the same events as the theme (`write_verbs`, once install.lua has wired it),
taking back every verb any lore or region brings (`known_verbs`) and keeping the rest.
`UserPromptSubmit` stamps when a turn began, so `Stop` plays `grace` only for turns of 20 s or more,
permission sounds ring once per 30 s, and nothing plays during an expedition. The Claude statusline
shows the model, the franchise's ornament with the region's character, the branch (outside nvim
only, from `.git/HEAD`), the bars, the cost and the duration.
