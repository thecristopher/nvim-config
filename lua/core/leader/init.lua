-- Binds the leader map from core/leader/actions, so groups, keys, which-key and the palette all
-- read the same list instead of each module setting its own keys.
local actions = require("core.leader.actions")

local M = {}

--- The bindings that need more than one call, named from BINDINGS.
M.HANDLERS = {
  buffer_delete = function()
    Snacks.bufdelete()
  end,
  buffer_delete_others = function()
    Snacks.bufdelete.other()
  end,
  make_executable = function()
    local file = vim.api.nvim_buf_get_name(0)
    local perm = vim.fn.getfperm(file)
    if perm == "" then
      return vim.notify("Save the file first", vim.log.levels.WARN)
    end
    vim.fn.setfperm(file, require("core.utils").executable_perm(perm))
    vim.notify(vim.fn.fnamemodify(file, ":t") .. " can run now")
  end,
  snapshot_selection = function()
    vim.api.nvim_feedkeys(vim.keycode(":Snapshot<cr>"), "n", false)
  end,
  -- the substitute comes typed out with the word as its replacement, <C-w> clears it to type a new one
  replace_word = function()
    vim.api.nvim_feedkeys(
      vim.keycode([[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]]),
      "n",
      false
    )
  end,
  undo_history = function()
    Snacks.picker.undo()
  end,
  zoom = function()
    Snacks.zen.zoom()
  end,
  toggle_fog = function()
    vim.g.eldentree_fog = vim.g.eldentree_fog == false
    vim.notify("Fog walls " .. (vim.g.eldentree_fog and "on" or "off"))
  end,
  toggle_autoroot = function()
    vim.g.eldentree_autoroot = vim.g.eldentree_autoroot == false
    vim.notify("Auto root " .. (vim.g.eldentree_autoroot and "on" or "off"))
  end,
  notifications_hide = function()
    Snacks.notifier.hide()
  end,
  notifications_history = function()
    Snacks.notifier.show_history()
  end,
}

local function runner(binding)
  if binding.call then
    local module, fn = actions.parse_call(binding.call)
    return function()
      require(module)[fn]()
    end
  end
  if binding.cmd then
    return "<cmd>" .. binding.cmd .. "<cr>"
  end
  return M.HANDLERS[binding.handler]
end

-- snacks toggles show their state in which-key, so they map through snacks once it has loaded
local function map_toggle(binding)
  local lhs = actions.lhs(binding.key)
  local option = binding.toggle:match("^option:(.+)$")
  local toggle = option and Snacks.toggle.option(option, { name = binding.desc })
    or Snacks.toggle[binding.toggle]({ name = binding.desc })
  toggle:map(lhs)
end

local function map_git_quick_keys()
  for _, entry in ipairs(require("core.git.actions").QUICK_KEYS) do
    vim.keymap.set("n", actions.lhs("g" .. entry.key), function()
      require("core.git")[entry.fn]()
    end, { desc = entry.desc })
  end
end

function M.setup()
  local toggles = {}
  for _, binding in ipairs(actions.BINDINGS) do
    if binding.toggle then
      table.insert(toggles, binding)
    else
      vim.keymap.set(
        binding.mode or "n",
        actions.lhs(binding.key),
        runner(binding),
        { desc = binding.desc, silent = true }
      )
    end
  end
  map_git_quick_keys()

  vim.api.nvim_create_autocmd("User", {
    pattern = "VeryLazy",
    once = true,
    callback = function()
      for _, binding in ipairs(toggles) do
        map_toggle(binding)
      end
    end,
  })
end

return M
