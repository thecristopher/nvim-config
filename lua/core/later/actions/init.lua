-- Pure logic for the plugins that load after the first frame: which ones and in what order.
local M = {}

-- what nobody touches in the first moment, the cmdline and the key hints first, the toys last
M.PLUGINS = {
  "noice.nvim",
  "which-key.nvim",
  "flash.nvim",
  "nvim-surround",
  "mini.ai",
  "mini.move",
  "nvim-ts-context-commentstring",
  "smear-cursor.nvim",
  "mini.animate",
  "claudecode.nvim",
  "back-to-basics",
}

-- the first frame is drawn by then, and a key typed right away still beats the queue
M.DELAY_MS = 30

--- The queued plugins still waiting, in queue order: known to lazy.nvim and not loaded yet.
---@param plugins table<string, table> lazy.nvim's plugins by name
---@param queue? string[] defaults to PLUGINS
---@return string[]
function M.pending(plugins, queue)
  local waiting = {}
  for _, name in ipairs(queue or M.PLUGINS) do
    local plugin = plugins[name]
    if plugin and not (plugin._ and plugin._.loaded) then
      table.insert(waiting, name)
    end
  end
  return waiting
end

return M
