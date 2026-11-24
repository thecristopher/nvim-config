# Repos

`lua/core/repos/`: background repo scanner, Sites of Grace picker (`<leader>fp`), auto root. A repo
counts only when its `.git` leads to a readable `HEAD`. Traveling saves the old project's session
(persistence) and restores the new one, unsaved buffers stay open. In Sites of Grace `<C-f>`,
`<C-g>` and `<C-o>` travel and open files, grep or recent on arrival. Open Folder sends repos
through the same travel, and `:BrowseFolders` walks folders in normal mode (`l` in, `h` up, `o`
open, `.` open here). Switching branch with `<leader>gb` keeps a session per branch
(`save_branch_session`, `restore_branch_session`).
