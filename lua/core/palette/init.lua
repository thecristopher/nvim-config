-- Everything Eldentree can do in one picker, each row with its key so the key sticks: the
-- curated entries first, then every other key in the leader map. <leader><leader> or ? on the
-- HUD opens it.
local actions = require("core.palette.actions")

local M = {}

-- every row lines its name, description and key up in columns, so the keys read as one list
local function formatter(widths)
  return function(item)
    return {
      { item.entry.icon, "SnacksPickerIcon" },
      { actions.fit(item.entry.name, widths.name), "SnacksPickerFile" },
      { "  " .. actions.fit(item.entry.desc, widths.desc), "SnacksPickerComment" },
      { "  " .. (item.entry.key or ""), "SnacksPickerSpecial" },
    }
  end
end

local function run(entry)
  if entry.feed then
    -- "m" lets the mapping remap, so toggles, handlers and calls all run the way the key does
    return vim.api.nvim_feedkeys(vim.keycode(entry.feed), "m", false)
  end
  if actions.wants_args(entry) then
    return vim.api.nvim_feedkeys(":" .. entry.cmd, "n", false)
  end
  vim.cmd(entry.cmd)
end

---Opens the palette.
function M.open()
  local leader = require("core.leader.actions")
  local entries = actions.with_bindings(actions.ENTRIES, leader.BINDINGS, leader.group_of)
  local widths = actions.column_widths(entries)
  local items = vim.tbl_map(function(entry)
    return { text = actions.search_text(entry), entry = entry }
  end, entries)

  Snacks.picker({
    -- the picker layout already frames every title in the skin's ornaments
    title = require("core.franchise").current().words.arts,
    items = items,
    format = formatter(widths),
    layout = { preset = "select", layout = { width = actions.window_width(widths, vim.o.columns) } },
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
