-- Treesitter: syntax, folding, text objects, context
-- main branch: master is frozen and its query predicates crash on Neovim 0.12

local parsers = {
  "bash", "c", "cmake", "comment", "cpp", "css", "diff",
  "dockerfile", "fish", "git_config", "git_rebase", "gitcommit",
  "gitignore", "go", "gomod", "gowork", "graphql", "html",
  "http", "java", "javascript", "jsdoc", "json", "json5",
  "lua", "luadoc", "luap", "make", "markdown",
  "markdown_inline", "python", "query", "regex", "ron", "rust",
  "scss", "sql", "svelte", "swift", "terraform", "toml", "tsx",
  "typescript", "vim", "vimdoc", "vue", "xml", "yaml",
  "zig", "php", "phpdoc", "prisma", "styled",
}

local function too_big(buf)
  if vim.bo[buf].filetype == "bigfile" then return true end
  local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
  return ok and stats and stats.size > 1024 * 1024
end

-- main no longer attaches itself, so every buffer with a parser gets highlights and indent here
local function start_treesitter(ev)
  if vim.g.vscode or too_big(ev.buf) then return end
  if not pcall(vim.treesitter.start, ev.buf) then return end
  vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
end

local function select_map(keys, query, desc)
  vim.keymap.set({ "x", "o" }, keys, function()
    require("nvim-treesitter-textobjects.select").select_textobject(query, "textobjects")
  end, { desc = desc })
end

local function move_map(keys, method, query, desc)
  vim.keymap.set({ "n", "x", "o" }, keys, function()
    require("nvim-treesitter-textobjects.move")[method](query, "textobjects")
  end, { desc = desc })
end

local function setup_textobjects()
  require("nvim-treesitter-textobjects").setup({
    select = { lookahead = true },
    move   = { set_jumps = true },
  })

  select_map("af", "@function.outer",    "outer function")
  select_map("if", "@function.inner",    "inner function")
  select_map("ac", "@class.outer",       "outer class")
  select_map("ic", "@class.inner",       "inner class")
  select_map("aa", "@parameter.outer",   "outer parameter")
  select_map("ia", "@parameter.inner",   "inner parameter")
  select_map("ai", "@conditional.outer", "outer conditional")
  select_map("ii", "@conditional.inner", "inner conditional")
  select_map("al", "@loop.outer",        "outer loop")
  select_map("il", "@loop.inner",        "inner loop")
  select_map("ab", "@block.outer",       "outer block")
  select_map("ib", "@block.inner",       "inner block")

  move_map("]f", "goto_next_start",     "@function.outer",  "Next function start")
  move_map("]c", "goto_next_start",     "@class.outer",     "Next class start")
  move_map("]a", "goto_next_start",     "@parameter.inner", "Next parameter")
  move_map("]F", "goto_next_end",       "@function.outer",  "Next function end")
  move_map("]C", "goto_next_end",       "@class.outer",     "Next class end")
  move_map("[f", "goto_previous_start", "@function.outer",  "Previous function start")
  move_map("[c", "goto_previous_start", "@class.outer",     "Previous class start")
  move_map("[a", "goto_previous_start", "@parameter.inner", "Previous parameter")
  move_map("[F", "goto_previous_end",   "@function.outer",  "Previous function end")
  move_map("[C", "goto_previous_end",   "@class.outer",     "Previous class end")

  local swap = require("nvim-treesitter-textobjects.swap")
  vim.keymap.set("n", "<leader>a", function() swap.swap_next("@parameter.inner") end, { desc = "Swap with next parameter" })
  vim.keymap.set("n", "<leader>A", function() swap.swap_previous("@parameter.inner") end, { desc = "Swap with previous parameter" })
end

-- Neovim 0.12 ships node selection as visual an/in, these keep the old muscle memory
local function setup_selection()
  vim.keymap.set("n", "<C-space>", "van", { remap = true, desc = "Start node selection" })
  vim.keymap.set("x", "<C-space>", "an", { remap = true, desc = "Grow node selection" })
  vim.keymap.set("x", "<bs>", "in", { remap = true, desc = "Shrink node selection" })
end

return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    build  = ":TSUpdate",
    lazy   = false, -- main does not support lazy loading
    config = function()
      -- building parsers needs the tree-sitter CLI (brew install tree-sitter-cli)
      if vim.fn.executable("tree-sitter") == 1 then
        require("nvim-treesitter").install(parsers)
      end
      vim.api.nvim_create_autocmd("FileType", {
        group    = vim.api.nvim_create_augroup("eldentree_treesitter", { clear = true }),
        callback = start_treesitter,
      })
      setup_selection()
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    event  = { "BufReadPost", "BufNewFile" },
    config = setup_textobjects,
  },

  -- Auto close and rename JSX/HTML tags as you type
  {
    "windwp/nvim-ts-autotag",
    event = { "BufReadPre", "BufNewFile" },
    opts  = {},
  },

  -- Treesitter context: shows current scope at top
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = { "BufReadPost", "BufNewFile" },
    opts  = {
      enable            = true,
      max_lines         = 3,
      min_window_height = 20,
      line_numbers      = true,
      multiline_threshold = 1,
      trim_scope        = "outer",
      mode              = "cursor",
      zindex            = 20,
      on_attach         = nil,
    },
    keys = {
      {
        "[x",
        function() require("treesitter-context").go_to_context(vim.v.count1) end,
        desc = "Go to context (up)",
      },
    },
  },
}
