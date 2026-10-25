-- Settings for recording the README demos with vhs: quiet, the same world on every take, and only
-- the made up repos scripts/record.sh builds. Loaded with `nvim --cmd "luafile $DEMO_LUA"`.
vim.g.eldentree_sound = false
vim.g.eldentree_franchise = vim.env.DEMO_FRANCHISE or "elden_ring"
vim.g.eldentree_region = vim.env.DEMO_REGION
vim.g.eldentree_title = vim.env.DEMO_TITLE == "1"
vim.g.eldentree_music = vim.env.DEMO_MUSIC == "1"
vim.g.eldentree_repo_roots = { vim.env.DEMO_ROOTS }
