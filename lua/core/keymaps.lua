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

map("n", "<leader>sv", "<cmd>vsplit<cr>", { desc = "Split vertical" })
map("n", "<leader>sh", "<cmd>split<cr>", { desc = "Split horizontal" })
map("n", "<leader>se", "<C-w>=", { desc = "Equalize splits" })

-- ── Buffers ──────────────────────────────────────────────────────────────────
map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next buffer" })
map("n", "<leader>bd", function()
  Snacks.bufdelete()
end, { desc = "Delete buffer" })
map("n", "<leader>bo", function()
  Snacks.bufdelete.other()
end, { desc = "Delete other buffers" })
map("n", "<leader>bD", "<cmd>%bdelete|e#<cr>", { desc = "Delete all buffers" })

-- ── File ─────────────────────────────────────────────────────────────────────
map("n", "<leader>w", "<cmd>write<cr>", { desc = "Save" })
map("n", "<leader>W", "<cmd>wall<cr>", { desc = "Save all" })
map("n", "<leader>q", "<cmd>quit<cr>", { desc = "Quit" })
map("n", "<leader>Q", "<cmd>qall!<cr>", { desc = "Force quit all" })

-- ── Editing ──────────────────────────────────────────────────────────────────
-- no jk or kj escape: rolling fast across the home row lands j and k inside timeoutlen and drops insert
map("v", "<", "<gv", { desc = "Indent left" })
map("v", ">", ">gv", { desc = "Indent right" })

map("n", "<A-j>", "<cmd>m .+1<cr>==", { desc = "Move line down" })
map("n", "<A-k>", "<cmd>m .-2<cr>==", { desc = "Move line up" })
map("v", "<A-j>", ":m '>+1<cr>gv=gv", { desc = "Move selection down" })
map("v", "<A-k>", ":m '<-2<cr>gv=gv", { desc = "Move selection up" })

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

-- ── UI toggles ───────────────────────────────────────────────────────────────
map("n", "<leader>un", function()
  Snacks.notifier.hide()
end, { desc = "Dismiss notifications" })
map("n", "<leader>uN", function()
  Snacks.notifier.show_history()
end, { desc = "Notification history" })
map("n", "<leader>uZ", function()
  Snacks.zen.zoom()
end, { desc = "Zoom window" })

-- ── Repos ────────────────────────────────────────────────────────────────────
map("n", "<leader>fp", function()
  require("core.repos").pick()
end, { desc = "Find repository" })
map("n", "<leader>uR", function()
  vim.g.eldentree_autoroot = vim.g.eldentree_autoroot == false
  vim.notify("Auto root " .. (vim.g.eldentree_autoroot and "on" or "off"))
end, { desc = "Toggle auto root" })

-- ── Links printed in terminals ───────────────────────────────────────────────
map("n", "<leader>to", function()
  require("core.links").open_last()
end, { desc = "Open the last link a terminal printed" })

-- ── Git quick actions ────────────────────────────────────────────────────────
for _, entry in ipairs(require("core.git.actions").QUICK_KEYS) do
  map("n", "<leader>g" .. entry.key, function()
    require("core.git")[entry.fn]()
  end, { desc = entry.desc })
end

map("n", "<leader>gw", function()
  require("core.phantom").show()
end, { desc = "Who wrote this (phantom)" })

-- ── Regions (themes) ─────────────────────────────────────────────────────────
map("n", "<leader>ut", function()
  require("core.themes").pick()
end, { desc = "Choose region theme" })
map("n", "<leader>uT", function()
  require("core.themes").cycle()
end, { desc = "Next region theme" })
map("n", "<leader>uf", function()
  require("core.franchise").pick()
end, { desc = "Choose today's franchise" })
map("n", "<leader>uo", function()
  require("core.terminal").pick_opacity()
end, { desc = "Choose terminal opacity" })
map("n", "<leader>uh", function()
  require("core.hud").open()
end, { desc = "Open the inventory HUD" })
map("n", "<leader>fM", function()
  require("core.map").open()
end, { desc = "Project map" })
map("n", "<leader>um", function()
  require("core.motion").toggle()
end, { desc = "Toggle animations" })
map("n", "<leader>cT", function()
  require("core.trial").run()
end, { desc = "Run tests (Trial)" })
map("n", "<leader>uF", function()
  vim.g.eldentree_fog = vim.g.eldentree_fog == false
  vim.notify("Fog walls " .. (vim.g.eldentree_fog and "on" or "off"))
end, { desc = "Toggle fog walls" })
map("n", "<leader>uB", function()
  require("core.boss").toggle()
end, { desc = "Toggle boss fights" })

-- ── Messages on the ground ───────────────────────────────────────────────────
map("n", "<leader>mw", function()
  require("core.messages").write()
end, { desc = "Write message" })
map("n", "<leader>md", function()
  require("core.messages").erase()
end, { desc = "Erase message" })
map("n", "<leader>ml", function()
  require("core.messages").pick()
end, { desc = "List messages" })

-- ── Command palette ─────────────────────────────────────────────────────────
map("n", "<leader><leader>", function()
  require("core.palette").open()
end, { desc = "Command palette" })

-- ── Music ───────────────────────────────────────────────────────────────────
map("n", "<leader>o", function()
  require("core.music").open()
end, { desc = "Now playing" })

-- ── ThePrimeagen's classics ─────────────────────────────────────────────────
-- the substitute comes typed out with the word as its replacement, <C-w> clears it to type a new one
map(
  "n",
  "<leader>rw",
  [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
  { desc = "Replace the word under the cursor in this file" }
)
map("n", "<leader>cx", function()
  local file = vim.api.nvim_buf_get_name(0)
  local perm = vim.fn.getfperm(file)
  if perm == "" then
    return vim.notify("Save the file first", vim.log.levels.WARN)
  end
  vim.fn.setfperm(file, require("core.utils").executable_perm(perm))
  vim.notify(vim.fn.fnamemodify(file, ":t") .. " can run now")
end, { desc = "Make this file executable" })

-- ── Snapshots ────────────────────────────────────────────────────────────────
map("n", "<leader>cp", "<cmd>Snapshot<cr>", { desc = "Snapshot the buffer as a PNG" })
map("x", "<leader>cp", ":Snapshot<cr>", { desc = "Snapshot the selection as a PNG", silent = true })

-- ── Undo history ─────────────────────────────────────────────────────────────
map("n", "<leader>fu", function()
  Snacks.picker.undo()
end, { desc = "Undo history" })

-- ── LSP (F12 and friends bind per buffer in core/dive) ───────────────────────
