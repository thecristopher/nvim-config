# Desk

`lua/core/desk/`: the manager desk. `:Desk` / `<leader>jd` / `d` on the HUD opens the Desk app
(`app_name` in the config, installed by the Claude desktop app under `~/Applications/Claude Apps/`)
and falls back to the artifact in the browser when the app is missing. Its link and settings live
in a private config (`~/.claude/skills/desk/config.json`, or `vim.g.eldentree_desk_config`), so
nothing company specific lands in this repo.

Nothing runs on a timer. Work starts when the state folder's `wake` file changes (`state_dir` in
the config, nvim's `eldentree_desk/` by default): opening the desk and `:Desk sync` write it, and
so does every Sync and action on the page when it runs in the Claude app, through the local MCP
server `desk-sync/scripts/mcp.mjs` the page reaches as `host:desk`. A launchd agent runs
`desk-sync/scripts/work.sh` when `wake` or `work.json` changes, and it starts a `/desk-sync work`
session when `wake` changed since the last session started and none is running. A click that lands
while a session runs starts the next one when that session writes `work.json`. Nothing gets
analyzed unless Cristopher sends it from the page. The desk's session never rings: the sound hook
skips the session id in `work.lock` (`core.desk.session_ids`).

Implement and review requests land as files in `inbox/`, written by the bridge on a click or by the
work session for requests queued from the browser. nvim watches the folder with
`vim.uv.new_fs_event` (each nvim claims a file with a rename so only one opens it). Implement
opens a tab with `claude "/ticket-implement KEY"` (`:DeskImplement KEY [repo]`). Review finds the
ticket's open PR with `gh search prs` in `github_org`, and when no PR mentions the key it scans the
clones for a branch named after it and asks `gh pr list --head` in that repo, then runs
`core/review` from the clone (`:DeskReview KEY`). What nvim did (the tab it opened, no PR found, a
clone missing, or waiting because you were typing) goes to `outbox/<queue_id>.json`, where the
bridge waits for it and hands it to the page.

`scripts/install.sh` installs the agent (`--uninstall` removes it), `:Desk status` reads the work
session and the inbox from their files, and `vim.g.eldentree_desk = false` turns the module off.
