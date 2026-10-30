-- Everything Eldentree can do in one picker, each row with its key so the key sticks.
-- <leader><leader> or ? on the HUD opens it.
local actions = require("core.palette.actions")

local M = {}

local function format(item)
  return {
    { item.entry.icon, "SnacksPickerIcon" },
    { item.entry.name, "SnacksPickerFile" },
    { "  " .. item.entry.desc, "SnacksPickerComment" },
    { "  " .. (item.entry.key or ""), "SnacksPickerSpecial" },
  }
end

local function run(entry)
  if actions.wants_args(entry) then
    return vim.api.nvim_feedkeys(":" .. entry.cmd, "n", false)
  end
  vim.cmd(entry.cmd)
end

---Opens the palette.
function M.open()
  local items = vim.tbl_map(function(entry)
    return { text = actions.search_text(entry), entry = entry }
  end, actions.ENTRIES)

  Snacks.picker({
    title = require("core.skin").title(require("core.franchise").current().words.arts),
    items = items,
    format = format,
    layout = { preset = "select" },
    confirm = function(picker, item)
      picker:close()
      if item then
        vim.schedule(function()
          run(item.entry)
        end)
      end
    end,
  })
end

return M
