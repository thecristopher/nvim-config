-- Pieces both HUD views share: the champion's name on a plaque, the changed files of the quest and
-- the footer with the message and the stats. Pure: they only turn data into rows of chunks.
local hud = require("core.hud.actions")

local M = {}

--- Returns what the HUD calls something in the franchise's words, from the model, or the plain
--- line when the model brings none (see lua/core/franchise/lines.lua, the keys after "hud.").
---@param model table
---@param key string like "quest" or "hint_use"
---@return string
function M.word(model, key)
  local said = (model.words or {})[key]
  if said then
    return said
  end
  local plain = require("core.franchise.lines")["hud." .. key] or key
  return require("core.franchise.actions").fill(plain, { sites = model.sites or "projects" })
end

--- Builds the key hints in the franchise's words, most important first.
---@param model table
---@param keys { [1]: string, [2]: string }[] each key and the word after "hint_", like { "K", "check" }
---@return string[] hints like "K Check"
function M.hints(model, keys)
  return vim.tbl_map(function(pair)
    return pair[1] .. " " .. M.word(model, "hint_" .. pair[2])
  end, keys)
end

-- the hints the roundtable and the dressing room show, Enter uses the item
M.USE_HINTS = {
  { "⏎", "use" },
  { "K", "check" },
  { "C", "combine" },
  { "⇥", "tabs" },
  { "hjkl", "move" },
  { "j", "quest" },
  { "s", "session" },
  { "q", "quit" },
}

--- Letterspaces the champion's name as wide as the room allows: carved, then banner style, then
--- plain, then the first name alone, never a name cut in the middle.
---@param character string
---@param width integer
---@return string
function M.champion_name(character, width)
  local upper = vim.fn.toupper(character)
  return hud.first_fit({
    require("core.hub.actions").spaced(character),
    require("core.banner.actions").spaced(character),
    upper,
    upper:match("^%S+"),
  }, width) or hud.fit(upper, width)
end

--- A sentence whole on one row, centered, or an empty row when it does not fit whole.
---@param text string|nil
---@param hl string
---@param width integer
---@return table[] chunks
function M.whole_line(text, hl, width)
  if not text or text == "" or vim.api.nvim_strwidth(text) > width then
    return {}
  end
  return hud.center({ { text, hl } }, width)
end

local STATUS_HL = {
  M = "EldenHudKey",
  A = "EldenHudTitle",
  D = "EldenHudDim",
  R = "EldenHudKey",
  ["?"] = "EldenHudCount",
}

local function change_chunks(line, width, selected)
  local code = vim.trim(line:sub(1, 2))
  local path = line:sub(4)
  local bg = selected and "EldenHudSlotSel" or nil
  return {
    {
      hud.pad(code, 3),
      STATUS_HL[code:sub(1, 1)] or "EldenHudCount",
      bg = bg,
      spot = selected and "cursor" or nil,
    },
    {
      hud.pad(hud.fit_name(path, width - 4), width - 3),
      selected and "EldenHudBanner" or "EldenHudDesc",
      bg = bg,
    },
  }
end

--- Lays changed files (porcelain lines) in two columns, or one in a narrow card, as many rows as given. When they do not
--- all fit, the last cell says how many more there are, and while one is selected the page that
--- holds it is shown instead.
---@param changes string[]
---@param width integer
---@param rows integer
---@param selected? integer the selected change, when the quest has the focus
---@param columns? integer 1 or 2, two by default
---@return table[] rows of chunks
function M.changes(changes, width, rows, selected, columns)
  columns = columns or 2
  local column = columns == 1 and width or math.floor((width - 2) / 2)
  local capacity = rows * columns
  if capacity == 0 then
    return {}
  end
  local first = selected and math.floor((selected - 1) / capacity) * capacity or 0
  local shown = math.min(#changes - first, capacity)
  if not selected and #changes > capacity then
    shown = capacity - 1
  end
  local cells = {}
  for cell = 1, shown do
    local index = first + cell
    cells[cell] = change_chunks(changes[index], column, index == selected)
  end
  if not selected and shown < #changes then
    cells[capacity] = { { ("+%d more"):format(#changes - shown), "EldenHudDim" } }
  end
  local out = {}
  for row = 1, rows do
    local left, right = cells[row], cells[row + rows]
    if not left then
      break
    end
    local chunks = hud.pad_chunks(left, column)
    if right then
      table.insert(chunks, { "  " })
      vim.list_extend(chunks, right)
    end
    table.insert(out, chunks)
  end
  return out
end

--- The item under the cursor in whichever pane has the focus.
---@param model table
---@return table|nil
function M.selected(model)
  if model.selected then
    return model.selected
  end
  if model.focus == "chest" and model.chest then
    return model.chest.items[model.cursor.chest or 1]
  end
  return model.tabs[model.tab].items[model.cursor.items or 1]
end

--- Tells which quest entry is selected: the last file or one of the changes.
---@param model table
---@return boolean last_selected, integer|nil change index
function M.quest_selection(model)
  if model.focus ~= "quest" then
    return false, nil
  end
  local index = model.cursor.quest or 1
  local status = model.status or {}
  if status.last_ready then
    if index == 1 then
      return true, nil
    end
    return false, index - 1
  end
  return false, index
end

--- How many quest entries the cursor can reach: the last file and the changes that have room.
---@param status table
---@param change_rows integer
---@return integer
function M.quest_count(status, change_rows)
  local changes = change_rows > 0 and #(status.changes or {}) or 0
  return (status.last_ready and 1 or 0) + changes
end

-- the review threads still open on the branch's PR, said after the changes
M.THREAD_GLYPH = "󰍩"

--- The line naming the quest: project, branch, how much changed and the review threads still open.
---@param status table
---@param width integer
---@param fallback string what to say outside a repo
---@return table[] chunks
function M.quest_line(status, width, fallback)
  if not status.project then
    return { { hud.fit_words(fallback, width) or "", "EldenHudDim" } }
  end
  local count = status.changes and #status.changes or nil
  local tally = count == nil and "counting…" or count == 0 and "clean" or (count .. " changed")
  local threads = (status.threads or 0) > 0 and ("    " .. M.THREAD_GLYPH .. " " .. status.threads)
    or ""
  -- the icons, the gaps and the dot take 14 cells, the branch gets what the name and tally leave
  local branch_width = math.max(
    4,
    width
      - 14
      - vim.api.nvim_strwidth(status.project)
      - vim.api.nvim_strwidth(tally)
      - vim.api.nvim_strwidth(threads)
  )
  return hud.clip({
    { "󰊢 ", "EldenHudIcon" },
    { status.project, "EldenHudBanner" },
    { "    ", nil },
    { " ", "EldenHudKey" },
    { hud.fit_words(status.branch or "?", branch_width) or "", "EldenHudName" },
    { "    " },
    { "● ", count and count > 0 and "EldenHudKey" or "EldenHudDim" },
    { tally, "EldenHudCount" },
    { threads, "EldenThread" },
  }, width)
end

--- The quest you left open: its title, the project line, the last file and the changed files,
--- always the same height so the stage never shifts when the changes arrive from git.
---@param model table
---@param width integer
---@param change_rows integer rows the changed files may take
---@param rule fun(label: string, width: integer): table[] the view's own title row
---@return table[] rows
function M.quest(model, width, change_rows, rule)
  local status = model.status or {}
  local last_selected, change = M.quest_selection(model)
  local quest = M.word(model, "quest")
  local title = rule(model.focus == "quest" and quest .. " ▼" or quest .. "  j", width)
  if model.focus == "quest" then
    title[1][2] = "EldenHudTitle"
  end
  local rows = {
    title,
    hud.indent({
      M.quest_line(status, width - 2, M.word(model, "no_quest")),
    }, 1)[1],
  }
  if status.last_file then
    local bg = last_selected and "EldenHudSlotSel" or nil
    table.insert(rows, {
      { last_selected and "▶ " or "  ", "EldenHudFrameSel" },
      { "󰘍 last  ", "EldenHudDim", bg = bg, spot = last_selected and "cursor" or nil },
      {
        hud.fit_name(status.last_file, width - 12),
        last_selected and "EldenHudBanner" or "EldenHudName",
        bg = bg,
      },
    })
  else
    table.insert(rows, {})
  end
  vim.list_extend(
    rows,
    hud.indent(M.changes(status.changes or {}, width - 4, change_rows, change), 2)
  )
  while #rows < 3 + change_rows do
    table.insert(rows, {})
  end
  return rows
end

-- the widest the song's bar grows, the song and artist take the rest
M.PLAYER_BAR = 16

--- The song playing right now on one row: playing or paused, the song and artist, and how far
--- along it is in the skin's bar. Nil when nothing plays.
---@param music table|nil { title, artist?, elapsed?, duration?, playing, bar = skin.music.bar }
---@param width integer
---@return table[]|nil chunks, centered in width
function M.player(music, width)
  if not music or not music.title or width < 12 then
    return nil
  end
  local bar_width = math.min(M.PLAYER_BAR, math.floor(width / 4))
  local fill = music.bar
    and bar_width >= 4
    and hud.bar_fill(music.elapsed, music.duration, bar_width - 1)
  -- the song and artist whole, the song alone, or the song cut where its words break
  local room = width - 2 - (fill and bar_width + 2 or 0)
  local song = hud.first_fit({
    music.artist and (music.title .. "  ·  " .. music.artist) or nil,
    music.title,
  }, room) or hud.fit_name(music.title, room)
  local chunks = { { music.playing and "\u{F0388} " or "\u{F03E4} ", "EldenMusicBarHead" } }
  table.insert(chunks, { song, "EldenHudDesc" })
  if fill then
    vim.list_extend(chunks, {
      { "  " },
      { music.bar.done:rep(fill), "EldenMusicBarDone" },
      { music.bar.head, "EldenMusicBarHead" },
      { music.bar.left:rep(bar_width - 1 - fill), "EldenMusicBarLeft" },
    })
  end
  return hud.center(chunks, width)
end

--- The footer under the whole stage: the player message and the stats, both centered. A view may
--- hand a line of its own (the Roundtable's attributes) to stand where the stats would.
---@param model table
---@param width integer
---@param line table[]|nil chunks in place of the stats
---@return table[] rows
function M.footer(model, width, line)
  local rows = { {} }
  local message = model.message or ""
  -- the hub's quill finds the message by its exact text, so it shows whole or not at all
  table.insert(rows, M.whole_line(message, "SnacksDashboardDesc", width))
  -- the song playing takes the stats' row, they matter least
  local player = M.player(model.music, width)
  if player then
    table.insert(rows, player)
  elseif line then
    table.insert(rows, line)
  elseif model.stats then
    table.insert(rows, M.whole_line(model.stats, "EldenHudDim", width))
  end
  return rows
end

M.FOOTER_ROWS = 3

return M
