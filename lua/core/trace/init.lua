-- :InsertTrace watches who ends insert mode: the keys right before it, typed or sent by a mapping or
-- plugin, written to eldentree_insert_trace.log in state. Off until you turn it on.
local actions = require("core.trace.actions")

local M = {}

local ns = vim.api.nvim_create_namespace("eldentree_trace")
local log_file = vim.fn.stdpath("state") .. "/eldentree_insert_trace.log"
local memory = {}
local group

local function floats()
  local count = 0
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_config(win).relative ~= "" then
      count = count + 1
    end
  end
  return count
end

local function record()
  local event = vim.v.event
  if not actions.left_insert(event.old_mode, event.new_mode) then
    return
  end
  local line = actions.entry(os.date("%H:%M:%S"), vim.deepcopy(memory), {
    file = vim.fn.expand("%:~:."),
    filetype = vim.bo.filetype,
    floats = floats(),
    mode = event.new_mode,
  })
  pcall(vim.fn.writefile, { line }, log_file, "a")
end

local function start()
  vim.on_key(function(key, typed)
    actions.remember(
      memory,
      actions.describe_key(vim.fn.keytrans(key), vim.fn.keytrans(typed or ""))
    )
  end, ns)
  group = vim.api.nvim_create_augroup("eldentree_trace", { clear = true })
  vim.api.nvim_create_autocmd("ModeChanged", { group = group, callback = record })
end

local function stop()
  vim.on_key(nil, ns)
  if group then
    vim.api.nvim_del_augroup_by_id(group)
  end
  group, memory = nil, {}
end

--- Turns the insert trace on or off.
function M.toggle()
  if group then
    stop()
    return vim.notify(
      "Insert trace off, the log stays in " .. log_file,
      vim.log.levels.INFO,
      { title = "Eldentree" }
    )
  end
  start()
  vim.notify(
    "Insert trace on, writing to " .. log_file,
    vim.log.levels.INFO,
    { title = "Eldentree" }
  )
end

function M.setup()
  vim.api.nvim_create_user_command("InsertTrace", M.toggle, { desc = "Log who ends insert mode" })
end

return M
