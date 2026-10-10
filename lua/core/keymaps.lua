local map = vim.keymap.set

-- ── Motion ──────────────────────────────────────────────────────────────────
map("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
map("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })

-- Centered scrolling
map("n", "<C-d>", "<C-d>zz", { desc = "Scroll down (centered)" })
map("n", "<C-u>", "<C-u>zz", { desc = "Scroll up (centered)" })
map("n", "n", "nzzzv",       { desc = "Next match (centered)" })
map("n", "N", "Nzzzv",       { desc = "Prev match (centered)" })

-- Join without moving cursor
map("n", "J", "mzJ`z", { desc = "Join lines" })

-- Yank to end of line (consistent with D, C)
map("n", "Y", "y$", { desc = "Yank to EOL" })

-- ── Windows ──────────────────────────────────────────────────────────────────
map("n", "<C-h>", "<C-w>h", { desc = "Window left" })
map("n", "<C-j>", "<C-w>j", { desc = "Window down" })
map("n", "<C-k>", "<C-w>k", { desc = "Window up" })
map("n", "<C-l>", "<C-w>l", { desc = "Window right" })

map("n", "<C-Up>",    "<cmd>resize +2<cr>",          { desc = "Increase height" })
map("n", "<C-Down>",  "<cmd>resize -2<cr>",          { desc = "Decrease height" })
map("n", "<C-Left>",  "<cmd>vertical resize -2<cr>", { desc = "Decrease width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase width" })

map("n", "<leader>sv", "<cmd>vsplit<cr>", { desc = "Split vertical" })
map("n", "<leader>sh", "<cmd>split<cr>",  { desc = "Split horizontal" })
map("n", "<leader>se", "<C-w>=",          { desc = "Equalize splits" })

-- ── Buffers ──────────────────────────────────────────────────────────────────
map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
map("n", "<S-l>", "<cmd>bnext<cr>",     { desc = "Next buffer" })
map("n", "<leader>bd", function() Snacks.bufdelete() end, { desc = "Delete buffer" })
map("n", "<leader>bo", function() Snacks.bufdelete.other() end, { desc = "Delete other buffers" })
map("n", "<leader>bD", "<cmd>%bdelete|e#<cr>", { desc = "Delete all buffers" })

-- ── File ─────────────────────────────────────────────────────────────────────
map("n", "<leader>w", "<cmd>write<cr>",   { desc = "Save" })
map("n", "<leader>W", "<cmd>wall<cr>",    { desc = "Save all" })
map("n", "<leader>q", "<cmd>quit<cr>",    { desc = "Quit" })
map("n", "<leader>Q", "<cmd>qall!<cr>",   { desc = "Force quit all" })

-- ── Editing ──────────────────────────────────────────────────────────────────
map("i", "jk", "<Esc>", { desc = "Escape" })
map("i", "kj", "<Esc>", { desc = "Escape" })

map("v", "<", "<gv", { desc = "Indent left" })
map("v", ">", ">gv", { desc = "Indent right" })

map("n", "<A-j>", "<cmd>m .+1<cr>==",     { desc = "Move line down" })
map("n", "<A-k>", "<cmd>m .-2<cr>==",     { desc = "Move line up" })
map("v", "<A-j>", ":m '>+1<cr>gv=gv",    { desc = "Move selection down" })
map("v", "<A-k>", ":m '<-2<cr>gv=gv",    { desc = "Move selection up" })

-- Paste without overwriting register
map("x", "<leader>p", '"_dP', { desc = "Paste (keep register)" })
map({ "n", "v" }, "<leader>d", '"_d', { desc = "Delete (no yank)" })

-- Clear search highlight
map("n", "<Esc>", "<cmd>nohlsearch<cr>", { silent = true })

-- Disable Ex mode
map("n", "Q", "<nop>")

-- ── Diagnostics ──────────────────────────────────────────────────────────────
map("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, { desc = "Prev diagnostic" })
map("n", "]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, { desc = "Next diagnostic" })
map("n", "<leader>e", vim.diagnostic.open_float, { desc = "Diagnostic float" })

-- ── UI toggles ───────────────────────────────────────────────────────────────
map("n", "<leader>un", function() Snacks.notifier.hide() end, { desc = "Dismiss notifications" })
map("n", "<leader>uN", function() Snacks.notifier.show_history() end, { desc = "Notification history" })
map("n", "<leader>uz", function() Snacks.zen() end, { desc = "Zen mode" })
map("n", "<leader>uZ", function() Snacks.zen.zoom() end, { desc = "Zoom window" })

-- ── Repos ────────────────────────────────────────────────────────────────────
map("n", "<leader>fp", function() require("core.repos").pick() end, { desc = "Find repository" })
map("n", "<leader>uR", function()
  vim.g.eldentree_autoroot = vim.g.eldentree_autoroot == false
  vim.notify("Auto root " .. (vim.g.eldentree_autoroot and "on" or "off"))
end, { desc = "Toggle auto root" })

-- ── LSP (F12 and friends bind per buffer in core/dive) ───────────────────────
