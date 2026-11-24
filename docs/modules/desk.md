# Desk

`lua/core/desk/`: the manager desk. `:Desk` / `<leader>jd` / `d` on the HUD opens the desk artifact,
whose link and settings live in a private config (`~/.claude/skills/desk/config.json`, or
`vim.g.eldentree_desk_config`), so nothing company specific lands in this repo. Nothing gets
analyzed unless Cristopher sends it from the page, and nothing waits for a manual sync: a lean haiku
listener (`desk-sync/listener.md`) reads the artifact's queue every minute while the desk is open:
`:Desk` writes `opened` in the state folder and starts it, a launchd agent running
`desk-sync/scripts/listener.sh` keeps it alive, and once the page stops writing `config/presence`
for 10 minutes the listener writes `idle` and stays down until the next `:Desk`. The desk's sessions
never ring: the sound hook skips the session ids in `listener.id` and `work.lock`
(`core.desk.session_ids`). Analyses, replies and syncs make it write `wake` in the state folder
(`state_dir` in the config, nvim's `eldentree_desk/` by default), and a second launchd agent runs
`scripts/work.sh` on that change, which starts `/desk-sync work` unless one already runs (the work
session syncs first, then drains the queue). Implement and review requests land as files in
`inbox/`, which nvim watches with `vim.uv.new_fs_event` (each nvim claims a file with a rename so
only one opens it): implement opens a tab with `claude "/ticket-implement KEY"` (`:DeskImplement KEY
[repo]`), review finds the ticket's open PR with `gh search prs` in `github_org` and runs
`core/review` on it from the clone (`:DeskReview KEY`). nvim never starts a Claude session for the
desk. `scripts/install.sh` installs both agents (`--uninstall` removes them), `:Desk sync` writes
`wake`, `:Desk status` reads the listener, the work session and the inbox from their files, `:Desk
pause` / `:Desk resume` stop and start the listener, and `vim.g.eldentree_desk = false` turns the
module off.
