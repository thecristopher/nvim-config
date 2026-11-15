-- Keys that are not leader keys, plus the two leader edits that also make sense inside VS Code.
-- Every other leader key lives in core/leader, so the whole map reads from one list.
local map = vim.keymap.set

-- ── Motion ──────────────────────────────────────────────────────────────────
map("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
map("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })

-- Centered scrolling
map("n", "<C-d>", "<C-d>zz", { desc = "Scroll down (centered)" })
map("n", "<C-u>", "<C-u>zz", { desc = "Scroll up (centered)" })
map("n", "n", "nzzzv", { desc = "Next match (centered)" })
map("n", "N", "Nzzzv", { desc = "Prev match (centered)" })

-- Join without moving cursor
map("n", "J", "mzJ`z", { desc = "Join lines" })

-- Yank to end of line (consistent with D, C)
map("n", "Y", "y$", { desc = "Yank to EOL" })

-- ── Windows ──────────────────────────────────────────────────────────────────
map("n", "<C-h>", "<C-w>h", { desc = "Window left" })
map("n", "<C-j>", "<C-w>j", { desc = "Window down" })
map("n", "<C-k>", "<C-w>k", { desc = "Window up" })
map("n", "<C-l>", "<C-w>l", { desc = "Window right" })

map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase height" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase width" })

-- ── Buffers ──────────────────────────────────────────────────────────────────
map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next buffer" })

-- ── Editing ──────────────────────────────────────────────────────────────────
-- no jk or kj escape: rolling fast across the home row lands j and k inside timeoutlen and drops insert
map("v", "<", "<gv", { desc = "Indent left" })
map("v", ">", ">gv", { desc = "Indent right" })

-- moving lines and selections with Alt+hjkl is mini.move's, in plugins/editor.lua

-- Paste without overwriting register
map("x", "<leader>p", '"_dP', { desc = "Paste (keep register)" })
map({ "n", "v" }, "<leader>d", '"_d', { desc = "Delete (no yank)" })

-- Clear search highlight
map("n", "<Esc>", "<cmd>nohlsearch<cr>", { silent = true })

-- Disable Ex mode
map("n", "Q", "<nop>")

-- ── Diagnostics ──────────────────────────────────────────────────────────────
map("n", "[d", function()
  vim.diagnostic.jump({ count = -1, float = true })
end, { desc = "Prev diagnostic" })
map("n", "]d", function()
  vim.diagnostic.jump({ count = 1, float = true })
end, { desc = "Next diagnostic" })
-- <leader>e reveals the file in the tree, so the float lives with the other diagnostics
map("n", "<leader>xd", vim.diagnostic.open_float, { desc = "Diagnostic float" })

-- LSP keys (F12 and friends) bind per buffer in core/dive
