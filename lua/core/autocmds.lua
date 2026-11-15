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
    vim.hl.on_yank({ timeout = 250 })
  end,
})

-- Restore cursor position on buffer open. Commit and rebase messages always start at the top,
-- a fresh message landing where the last one ended would put the cursor mid sentence
local fresh_every_time = { gitcommit = true, gitrebase = true }
au("BufReadPost", {
  group = aug("restore_cursor"),
  callback = function(ev)
    if fresh_every_time[vim.bo[ev.buf].filetype] then
      return
    end
    local mark = vim.api.nvim_buf_get_mark(ev.buf, '"')
    local lcount = vim.api.nvim_buf_line_count(ev.buf)
    local win = vim.fn.bufwinid(ev.buf)
    if win ~= -1 and mark[1] > 0 and mark[1] <= lcount then
      vim.api.nvim_win_set_cursor(win, mark)
    end
  end,
})

-- core/resize puts the layout back when the terminal resizes, it knows the tree and Claude panel

-- Close utility windows with q
au("FileType", {
  group = aug("close_with_q"),
  pattern = {
    "help",
    "lspinfo",
    "man",
    "notify",
    "qf",
    "spectre_panel",
    "startuptime",
    "neotest-output",
    "checkhealth",
    "neotest-summary",
    "neotest-output-panel",
    "PlenaryTestPopup",
    "query",
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

-- The cursor line warms up while typing and the line number takes the mode's color,
-- both fading over instead of snapping so the switch feels like breath, not a blink
local function paint_mode(mode)
  local themes = require("core.themes.actions")
  local p = require("core.themes").palette()
  local look = themes.mode_look(p, themes.derive(p), mode)
  local motion = require("core.motion")
  motion.fade_hl("CursorLine", { bg = look.cursorline }, { duration = 180 })
  motion.fade_hl("CursorLineNr", { fg = look.number, bold = true }, { duration = 180 })
end
au("ModeChanged", {
  group = aug("mode_paint"),
  callback = function()
    paint_mode(vim.v.event.new_mode)
  end,
})

-- Trailing whitespace is trimmed on the changed lines only, in core/whitespace

-- Auto-create parent directories on save
au("BufWritePre", {
  group = aug("auto_mkdir"),
  callback = function(ev)
    if ev.match:match("^%w%w+://") then
      return
    end
    local dir = vim.fn.fnamemodify(ev.match, ":p:h")
    if vim.fn.isdirectory(dir) == 0 then
      vim.fn.mkdir(dir, "p")
    end
  end,
})
