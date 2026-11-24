# Desk

`lua/core/desk/`: the manager desk. `:Desk` / `<leader>jd` / `d` on the HUD opens the desk artifact,
whose link and settings live in a private config (`~/.claude/skills/desk/config.json`, or
`vim.g.eldentree_desk_config`), so nothing company specific lands in this repo. Nothing runs
between visits: opening the desk writes `wake` in the state folder (`state_dir` in the config,
nvim's `eldentree_desk/` by default), a launchd agent runs `desk-sync/scripts/work.sh` on that
change, and it starts one `/desk-sync work` session unless one already runs. That session syncs,
then drains what the page queued, including what gets queued while it still runs. Anything queued
after it ends waits for the next time the desk opens, and nothing gets analyzed unless Cristopher
sends it from the page. The page itself only loads on open and on its Sync button, it never polls.
The desk's session never rings: the sound hook skips the session id in `work.lock`
(`core.desk.session_ids`). Implement and review requests land as files in `inbox/`, which nvim
watches with `vim.uv.new_fs_event` (each nvim claims a file with a rename so only one opens it):
implement opens a tab with `claude "/ticket-implement KEY"` (`:DeskImplement KEY [repo]`), review
finds the ticket's open PR with `gh search prs` in `github_org` and runs `core/review` on it from
the clone (`:DeskReview KEY`). `scripts/install.sh` installs the agent (`--uninstall` removes it),
`:Desk sync` writes `wake` without opening the page, `:Desk status` reads the work session and the
inbox from their files, and `vim.g.eldentree_desk = false` turns the module off.
