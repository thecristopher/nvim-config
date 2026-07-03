local function au(event, opts)
  vim.api.nvim_create_autocmd(event, opts)
end
local function aug(name)
  return vim.api.nvim_create_augroup("eldentree_" .. name, { clear = true })
end

-- Highlight yanked text briefly
au("TextYankPost", {
  group = aug("yank_highlight"),
  callback = function()
    vim.highlight.on_yank({ timeout = 250 })
  end,
})

-- Restore cursor position on buffer open
au("BufReadPost", {
  group = aug("restore_cursor"),
  callback = function(ev)
    local mark = vim.api.nvim_buf_get_mark(ev.buf, '"')
    local lcount = vim.api.nvim_buf_line_count(ev.buf)
    if mark[1] > 0 and mark[1] <= lcount then
      vim.api.nvim_win_set_cursor(0, mark)
    end
  end,
})

-- Equalize splits after terminal resize
au("VimResized", {
  group = aug("resize_splits"),
  callback = function()
    local curr = vim.api.nvim_get_current_tabpage()
    vim.cmd("tabdo wincmd =")
    vim.api.nvim_set_current_tabpage(curr)
  end,
})

-- Close utility windows with q
au("FileType", {
  group = aug("close_with_q"),
  pattern = {
    "help", "lspinfo", "man", "notify", "qf", "spectre_panel",
    "startuptime", "neotest-output", "checkhealth", "neotest-summary",
    "neotest-output-panel", "PlenaryTestPopup", "query",
  },
  callback = function(ev)
    vim.bo[ev.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = ev.buf, silent = true })
  end,
})

-- Check if file changed outside nvim
au({ "FocusGained", "TermClose", "TermLeave" }, {
  group = aug("checktime"),
  callback = function()
    if vim.o.buftype ~= "nofile" then
      vim.cmd("silent! checktime")
    end
  end,
})

-- Spell and wrap in prose files
au("FileType", {
  group = aug("prose"),
  pattern = { "markdown", "gitcommit", "text" },
  callback = function()
    vim.opt_local.spell = true
    vim.opt_local.wrap = true
    vim.opt_local.conceallevel = 0
  end,
})

-- Disable mini.animate cursor trail while typing (it smears/lags behind
-- the real cursor on every keystroke, making insert-mode position unclear)
au({ "InsertEnter" }, {
  group = aug("no_cursor_animate_insert"),
  callback = function()
    vim.b.minianimate_disable = true
  end,
})
au({ "InsertLeave" }, {
  group = aug("no_cursor_animate_insert"),
  callback = function()
    vim.b.minianimate_disable = false
  end,
})

-- Brighten the cursor line while typing so your position stays obvious
-- even when the terminal's caret color/shape is hard to spot (the base
-- CursorLine tint is deliberately subtle for normal-mode browsing)
au({ "InsertEnter" }, {
  group = aug("cursorline_insert"),
  callback = function()
    vim.api.nvim_set_hl(0, "CursorLine", { bg = "#332912" })
  end,
})
au({ "InsertLeave" }, {
  group = aug("cursorline_insert"),
  callback = function()
    vim.api.nvim_set_hl(0, "CursorLine", { bg = "#1A1714" })
  end,
})

-- Strip trailing whitespace on save (respects filetype exclusions)
local ws_exclude = { "markdown", "diff" }
au("BufWritePre", {
  group = aug("strip_whitespace"),
  callback = function()
    if vim.tbl_contains(ws_exclude, vim.bo.filetype) then return end
    local view = vim.fn.winsaveview()
    vim.cmd([[silent! %s/\s\+$//e]])
    vim.fn.winrestview(view)
  end,
})

-- Auto-create parent directories on save
au("BufWritePre", {
  group = aug("auto_mkdir"),
  callback = function(ev)
    if ev.match:match("^%w%w+://") then return end
    local dir = vim.fn.fnamemodify(ev.match, ":p:h")
    if vim.fn.isdirectory(dir) == 0 then
      vim.fn.mkdir(dir, "p")
    end
  end,
})
