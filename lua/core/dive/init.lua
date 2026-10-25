-- F12 and friends: jump, peek and rename like VS Code, but prettier
local actions = require("core.dive.actions")

local M = {}

-- hover floats are dressed like an item description, the category is read when K is pressed
local tome = { category = "Item" }

local function dress_hover(win)
  vim.wo[win].winhighlight = "Normal:EldenTome,FloatBorder:EldenTomeBorder,FloatTitle:EldenTomeTitle,FloatFooter:EldenTomeFooter"
  pcall(vim.api.nvim_win_set_config, win, { footer = { { " " .. tome.category .. " ", "EldenTomeFooter" } }, footer_pos = "right" })
end

-- only floats opened for hover are touched, every other preview keeps its own look
local function install_tome()
  if tome.installed then return end
  tome.installed = true
  local open = vim.lsp.util.open_floating_preview
  vim.lsp.util.open_floating_preview = function(contents, syntax, opts)
    local buf, win = open(contents, syntax, opts)
    if opts and opts.focus_id == "textDocument/hover" and win and vim.api.nvim_win_is_valid(win) then dress_hover(win) end
    return buf, win
  end
end

local function hover()
  install_tome()
  local ok, captures = pcall(vim.treesitter.get_captures_at_cursor, 0)
  tome.category = actions.item_category(ok and captures or {})
  local title = " ◈ " .. vim.fn.expand("<cword>") .. " "
  vim.lsp.buf.hover({ border = require("core.skin").border(), max_width = 90, title = { { title, "EldenTomeTitle" } }, title_pos = "left" })
end

local handlers = {
  definition           = function() Snacks.picker.lsp_definitions() end,
  references           = function() Snacks.picker.lsp_references() end,
  implementation       = function() Snacks.picker.lsp_implementations() end,
  type_definition      = function() Snacks.picker.lsp_type_definitions() end,
  declaration          = function() Snacks.picker.lsp_declarations() end,
  peek_definition      = function() vim.cmd("Glance definitions") end,
  peek_references      = function() vim.cmd("Glance references") end,
  peek_implementations = function() vim.cmd("Glance implementations") end,
  hover                = hover,
  code_action          = function() vim.lsp.buf.code_action() end,

  -- typed out like IncRename wants so the live preview kicks in
  rename = function()
    require("lazy").load({ plugins = { "inc-rename.nvim" } })
    vim.api.nvim_feedkeys(":IncRename " .. vim.fn.expand("<cword>"), "n", false)
  end,

  -- move the cursor to the click first, then jump from there
  definition_at_mouse = function()
    local mouse = vim.fn.getmousepos()
    if mouse.winid == 0 then return end
    vim.api.nvim_set_current_win(mouse.winid)
    vim.api.nvim_win_set_cursor(mouse.winid, { mouse.line, math.max(mouse.column - 1, 0) })
    Snacks.picker.lsp_definitions()
  end,
}

function M.attach(buf)
  for _, map in ipairs(actions.expand(actions.bindings)) do
    vim.keymap.set(map.mode, map.lhs, handlers[map.action], {
      buffer = buf,
      desc = "LSP: " .. map.desc,
      -- nvim 0.11 ships gra/grn/grr, without this "gr" waits for a third key
      nowait = map.lhs == "gr",
    })
  end

  vim.keymap.set("i", "<C-k>", function() vim.lsp.buf.signature_help({ border = require("core.skin").border() }) end, { buffer = buf, desc = "LSP: Signature help" })
  vim.keymap.set("n", "<leader>uh", function()
    vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = buf }), { bufnr = buf })
  end, { buffer = buf, desc = "Toggle inlay hints" })

  local tb = function(method) return function() require("telescope.builtin")[method]() end end
  vim.keymap.set("n", "<leader>ci", tb("lsp_incoming_calls"), { buffer = buf, desc = "LSP: Incoming calls" })
  vim.keymap.set("n", "<leader>co", tb("lsp_outgoing_calls"), { buffer = buf, desc = "LSP: Outgoing calls" })
  vim.keymap.set("n", "<leader>cs", function() Snacks.picker.lsp_symbols() end, { buffer = buf, desc = "LSP: Document symbols" })
  vim.keymap.set("n", "<leader>cS", function() Snacks.picker.lsp_workspace_symbols() end, { buffer = buf, desc = "LSP: Workspace symbols" })
end

M.handlers = handlers

return M
