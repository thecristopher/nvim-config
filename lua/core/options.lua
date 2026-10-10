local opt = vim.opt

-- UI
opt.termguicolors = true
opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.signcolumn = "yes"
opt.colorcolumn = "100"
opt.showmode = false
opt.ruler = false
opt.cmdheight = 1
opt.laststatus = 3
opt.pumheight = 10
opt.pumblend = 10
opt.winblend = 5
opt.wrap = false
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.conceallevel = 2
opt.splitright = true
opt.splitbelow = true
opt.equalalways = false

-- Files & persistence
opt.swapfile = false
opt.backup = false
opt.undofile = true
opt.undolevels = 10000
opt.confirm = true
opt.fileencoding = "utf-8"
opt.autoread = true

-- Indentation
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.softtabstop = 2
opt.smartindent = true
opt.shiftround = true

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = false
opt.incsearch = true
opt.grepformat = "%f:%l:%c:%m"
opt.grepprg = "rg --vimgrep"

-- Performance
opt.updatetime = 100
opt.timeoutlen = 300
opt.lazyredraw = false
opt.redrawtime = 1500

-- Mouse & clipboard
opt.mouse = "a"
opt.mousemoveevent = true -- hover highlights in bufferline and breadcrumbs
opt.mousescroll = "ver:3,hor:6"
opt.smoothscroll = true -- wrapped lines scroll by screen line instead of jumping
opt.clipboard = "unnamedplus"

-- Minified bundles have 50k char lines, highlighting past this is wasted effort
opt.synmaxcol = 300

-- Completion
opt.completeopt = "menu,menuone,noselect"
opt.wildmode = "longest:full,full"

-- Folding (treesitter-based)
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldlevel = 99
opt.foldlevelstart = 99
opt.foldenable = true

-- List & fill characters
opt.list = true
opt.listchars = { tab = "→ ", trail = "·", nbsp = "␣" }
opt.fillchars = {
  foldopen  = "▾",
  foldclose = "▸",
  foldsep   = " ",
  fold      = " ",
  diff      = "╱",
  eob       = " ",
}

-- Spell
opt.spelllang = { "en_us" }
opt.spelloptions = "camel"

-- Misc
opt.sessionoptions = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp", "folds" }
opt.shortmess:append({ W = true, I = true, c = true, C = true })

-- Disable built-in file browser (neo-tree handles it)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- the Claude native installer drops claude.exe here but often never makes it onto PATH
if vim.fn.has("win32") == 1 then
  local claude_bin = (vim.env.USERPROFILE or "") .. "\\.local\\bin"
  if not vim.env.PATH:lower():find(claude_bin:lower(), 1, true) then
    vim.env.PATH = claude_bin .. ";" .. vim.env.PATH
  end
end
