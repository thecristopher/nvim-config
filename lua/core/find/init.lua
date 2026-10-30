-- The pickers that need more than a one line Snacks call. Everything else in <leader>f
-- calls Snacks.picker straight from its key.
local actions = require("core.find.actions")

local M = {}

---Recent files, the current repo's by default. <C-a> flips to every recent file and back,
---keeping what was typed.
---@param scope? "repo"|"all"
---@param pattern? string
function M.recent(scope, pattern)
  scope = scope or "repo"
  Snacks.picker.recent({
    title = actions.recent_title(scope),
    pattern = pattern,
    filter = { cwd = scope == "repo" },
    actions = {
      flip_scope = function(picker)
        local typed = picker.input:get()
        picker:close()
        vim.schedule(function()
          M.recent(actions.other_scope(scope), typed)
        end)
      end,
    },
    win = { input = { keys = { ["<C-a>"] = { "flip_scope", mode = { "i", "n" } } } } },
  })
end

---Branches, switching with the session of each one: the files of the branch you leave are kept
---and the ones of the branch you arrive at come back.
function M.branches()
  Snacks.picker.git_branches({
    confirm = function(picker, item)
      picker:close()
      if item and item.branch and not item.current then
        require("core.git").checkout(item.branch)
      end
    end,
  })
end

return M
