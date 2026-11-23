-- The HUD: the start screen dressed as the franchise's inventory. A cursor walks the slots with hjkl,
-- Tab changes category, Enter uses the item (or opens the COMMAND menu in Resident Evil), K checks it
-- and C combines it. The hub's ambient life (shimmer, weather, the quill) runs on top of it.
local actions = require("core.hud.actions")
local items = require("core.hud.items")

local M = {}

local ns = vim.api.nvim_create_namespace("eldentree_hud")
local state
local stdin_given = false
-- when this nvim started, the call time on the dressing room's call sheet
local session_start = os.date("%H:%M")

local function style()
  return require("core.franchise").current().skin.dashboard
end

-- every view in core/hud/views a skin can name, anything else falls back to the roundtable
local VIEWS = { roundtable = true, inventory = true, wardrobe = true }

local function view()
  return require("core.hud.views." .. (VIEWS[style()] and style() or "roundtable"))
end

-- the HUD lives in whichever window shows its buffer, so a split that moves on to another buffer
-- or a closed zoom float hands it back instead of leaving the portrait behind
local function valid()
  if not state or not vim.api.nvim_buf_is_valid(state.buf) then
    return false
  end
  local showing = vim.fn.win_findbuf(state.buf)
  local win = actions.hud_window(vim.api.nvim_get_current_win(), state.win, showing)
  if not win then
    return false
  end
  state.win = win
  return true
end

-- highlights -----------------------------------------------------------------------------

local function palette_and_blend()
  return require("core.themes").palette(), require("core.themes.actions").blend
end

local function define_highlights()
  local p, blend = palette_and_blend()
  for name, look in pairs(actions.hud_groups(p, blend, style() == "inventory")) do
    vim.api.nvim_set_hl(0, name, look)
  end
end

-- transitions ----------------------------------------------------------------------------
-- every one starts from a lit or sunk look and fades to rest on core/motion's clock, so they still
-- with <leader>um, during an expedition and while a macro replays

local function fade_to_rest(from, duration)
  local p, blend = palette_and_blend()
  local rest = actions.hud_groups(p, blend, style() == "inventory")
  local motion = require("core.motion")
  for name, look in pairs(from) do
    vim.api.nvim_set_hl(0, name, look)
    motion.fade_hl(name, rest[name], { duration = duration })
  end
end

-- the slot the cursor lands on glows and settles
local function pulse_selection()
  local p, blend = palette_and_blend()
  fade_to_rest(actions.selection_flash(p, blend), 220)
end

-- a new tab flashes its plate or rule as the selection lands in it
local function pulse_tab()
  local p, blend = palette_and_blend()
  local flash = actions.selection_flash(p, blend)
  flash.EldenHudTabSel = style() == "inventory" and { fg = p.base, bg = p.text, bold = true }
    or { fg = p.text, bold = true }
  flash.EldenHudRuleSel = { fg = p.text }
  fade_to_rest(flash, 260)
end

-- the whole HUD rises out of the background when it opens
local function entrance()
  local p, blend = palette_and_blend()
  local rest = actions.hud_groups(p, blend, style() == "inventory")
  fade_to_rest(actions.sunk(rest, p.base, blend, 0.15), 320)
end

-- model ----------------------------------------------------------------------------------

-- the review threads still open on the branch's PR, nil without one or before GitHub answered
local function open_threads()
  local ok, threads = pcall(require, "core.threads")
  if not ok or type(threads.count) ~= "function" then
    return nil
  end
  local found, count = pcall(threads.count)
  return found and count or nil
end

local function status()
  local region = require("core.themes").current()
  local last = require("core.results").last()
  return vim.tbl_extend("force", items.quest(), {
    character = region.character,
    area = region.title,
    purse = require("core.runes").held(),
    threads = open_threads(),
    last_run = last and ("Rank %s  ·  %s"):format(
      last.rank,
      require("core.results.actions").duration(last.seconds)
    ) or nil,
  })
end

-- the world's HUD words: what each view calls its stats, tabs and kinds
local function hud_lore()
  return require("core.franchise").current().hud or {}
end

local function read_chronicle()
  local ok, lines = pcall(vim.fn.readfile, vim.fn.stdpath("state") .. "/eldentree_chronicle.json")
  local decoded_ok, decoded = pcall(vim.json.decode, ok and table.concat(lines, "\n") or "")
  return decoded_ok and type(decoded) == "table" and decoded or {}
end

-- the language servers at work right now, one per name
local function servers()
  local names = {}
  for _, client in ipairs(vim.lsp.get_clients()) do
    names[client.name] = true
  end
  return vim.tbl_count(names)
end

-- the champion's attributes on the Roundtable, read from what the run already counts
local function attributes()
  local said = hud_lore().stats or {}
  local run = require("core.results").current()
  local streak =
    require("core.hud.actions.trophies").current_streak(read_chronicle(), os.date("%Y-%m-%d"))
  local held = require("core.runes").held():gsub("^%S+%s+", "")
  return {
    { said.level or "Level", require("core.results.actions").rank(run) or "-" },
    { said.runes or "Runes", held },
    { said.vigor or "Vigor", tostring(run.saves) },
    { said.mind or "Mind", tostring(servers()) },
    { said.endurance or "Endurance", tostring(streak) },
    { said.arcane or "Arcane", tostring(run.fixes) },
  }
end

local CONDITION_HL =
  { fine = "EldenHudFine", caution = "EldenHudCaution", danger = "EldenHudDanger" }

-- the survivor's condition, read from every open buffer's diagnostics the way the ECG reads one
local function condition()
  local severity = vim.diagnostic.severity
  local counts = vim.diagnostic.count(nil)
  local key =
    require("core.ecg.actions").condition(counts[severity.ERROR] or 0, counts[severity.WARN] or 0)
  local said = hud_lore().stats or {}
  return { word = said[key] or key:upper(), hl = CONDITION_HL[key] }
end

-- what only one view draws: the Roundtable's attributes, the safe room's condition and ribbons
local function view_extras()
  if style() == "roundtable" then
    return { attributes = attributes() }
  end
  if style() == "inventory" then
    local words = require("core.franchise").current().words
    return {
      condition = condition(),
      ribbons = {
        word = (hud_lore().stats or {}).ribbons or words.ink_ribbons or "INK RIBBON",
        count = require("core.results").current().saves,
      },
    }
  end
  return {}
end

local function greeting()
  local hour = tonumber(os.date("%H"))
  local part = hour < 5 and "night"
    or hour < 12 and "morning"
    or hour < 18 and "afternoon"
    or "evening"
  return require("core.franchise").line("hud.greeting_" .. part)
end

local function stats()
  local lazy = require("lazy").stats()
  return ("Neovim %s  ·  %d plugins  ·  %.0fms  ·  %d %s"):format(
    tostring(vim.version()):match("^[%d.]+"),
    lazy.count,
    lazy.startuptime,
    #require("core.repos").list(),
    require("core.franchise").current().words.sites_found
  )
end

-- the region's image for the view in use, and whether it is a whole figure
local function portrait_image()
  return actions.image_for(require("core.themes").current(), view().SHOWS_FIGURES == true)
end

local function portrait_file()
  return vim.fn.stdpath("config") .. "/images/portraits/" .. (portrait_image() or "")
end

-- a region without its portrait yet, or a terminal that can draw neither pixels nor chafa, goes without
local function portrait_available()
  if vim.fn.filereadable(portrait_file()) == 0 then
    return false
  end
  local terminal = require("core.terminal")
  return vim.fn.executable("chafa") == 1
    or terminal.awaiting_images()
    or terminal.can_draw(portrait_file())
end

-- the song playing, as the mini player draws it, nil while nothing plays or core/music has no
-- now_playing yet
local function now_playing()
  local ok, music = pcall(require, "core.music")
  if not ok or type(music.now_playing) ~= "function" then
    return nil
  end
  local track = music.now_playing()
  if type(track) ~= "table" or not track.title then
    return nil
  end
  return {
    title = track.title,
    artist = track.artist ~= "" and track.artist or nil,
    elapsed = music.elapsed(),
    duration = track.duration,
    playing = track.playing,
    bar = require("core.skin").current().music.bar,
  }
end

local function model()
  -- the items may have changed since the HUD was left, the cursor never points past them
  state.cursor.items =
    actions.clamp(state.cursor.items, 1, math.max(1, #state.tabs[state.tab].items))
  state.cursor.chest =
    actions.clamp(state.cursor.chest, 1, math.max(1, #(state.chest and state.chest.items or {})))
  local quest_status = status()
  state.quest = items.quest_items(quest_status)
  -- the changes arrive and leave with git, the cursor never points past them
  state.cursor.quest = math.max(1, math.min(state.cursor.quest or 1, #state.quest))
  if state.focus == "quest" and #state.quest == 0 then
    state.focus = "items"
  end
  local region = require("core.themes").current()
  local words = require("core.franchise").current().words
  return vim.tbl_extend("force", view_extras(), {
    width = vim.api.nvim_win_get_width(state.win),
    height = vim.api.nvim_win_get_height(state.win),
    tabs = state.tabs,
    tab = state.tab,
    focus = state.focus,
    cursor = state.cursor,
    offset = state.offset,
    chest = state.chest,
    menu = state.menu,
    message = '"' .. require("core.hub").message() .. '"',
    character = region.character,
    area = region.title,
    hub = words.hub,
    sites = words.sites,
    greeting = greeting(),
    date = os.date("%A %d %B  ·  %H:%M"),
    date_short = os.date("%a %d  ·  %H:%M"),
    date_day = os.date("%a %d"),
    clock = os.date("%H:%M"),
    session_start = session_start,
    hud = hud_lore(),
    stats = state.stats,
    portrait = portrait_available(),
    figure = select(2, portrait_image()),
    examine = require("core.franchise").current().chrome.examine,
    -- every label and hint in the franchise's own words
    words = require("core.franchise").lines("hud", { sites = words.sites }),
    status = quest_status,
    selected = M.selected(),
    -- how much of the description has typed itself in, nil once it is whole
    typed = state.typed,
    -- how far the glint has run along the selected frame, nil once it settled
    glint = state.glint,
    music = now_playing(),
  })
end

-- drawing --------------------------------------------------------------------------------

-- the stage sits in the middle of the window, the weather drifts through the margins around it
local function frame_vertically(drawn, height)
  local top = math.max(0, math.floor((height - #drawn.lines) / 2))
  local lines = {}
  for _ = 1, top do
    table.insert(lines, "")
  end
  vim.list_extend(lines, drawn.lines)
  while #lines < height do
    table.insert(lines, "")
  end
  for _, mark in ipairs(drawn.marks) do
    mark[1] = mark[1] + top
  end
  drawn.cursor.row = drawn.cursor.row + top
  for _, anchor in pairs(drawn.anchors) do
    anchor.row = anchor.row + top
  end
  drawn.lines = lines
  return drawn
end

local function paint(lines, marks)
  vim.bo[state.buf].modifiable = true
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
  vim.bo[state.buf].modifiable = false
  vim.api.nvim_buf_clear_namespace(state.buf, ns, 0, -1)
  for _, mark in ipairs(marks) do
    vim.api.nvim_buf_set_extmark(
      state.buf,
      ns,
      mark[1],
      mark[2],
      { end_col = mark[3], hl_group = mark[4], priority = mark[5] or 200 }
    )
  end
end

local function place_cursor(lines, cursor)
  local line = lines[cursor.row]
  if not line then
    return
  end
  pcall(vim.api.nvim_win_set_cursor, state.win, { cursor.row, actions.byte_col(line, cursor.col) })
  vim.api.nvim_win_call(state.win, function()
    vim.fn.winrestview({ topline = 1, leftcol = 0 })
  end)
end

--- Redraws the HUD, and gathers its items again first when reload is true.
---@param reload boolean|nil
-- another float can ask for the portrait to step aside, the terminal paints images over every window
local portrait_hidden = false
-- where the HUD was left, so opening it again lands on the same tab and slot
local last_place = nil

function M.refresh(reload)
  if not valid() then
    return
  end
  -- a franchise switch repaints the colors before it announces itself, so the tabs may still belong
  -- to the other world: they are gathered again, from the first slot, whenever the style changed
  if state.style ~= style() then
    state.tab, state.focus, state.menu = 1, "items", nil
    state.cursor, state.offset =
      { items = 1, chest = 1, quest = 1 }, { items = 0, chest = 0, quest = 0 }
    reload = true
  end
  if reload then
    state.style = style()
    state.tabs, state.chest = items.tabs(state.style)
    state.stats = stats()
  end
  state.tab = math.min(state.tab, #state.tabs)
  local drawn = frame_vertically(view().render(model()), vim.api.nvim_win_get_height(state.win))
  state.grids, state.anchors = drawn.grids, drawn.anchors
  for focus, grid in pairs(drawn.grids) do
    state.offset[focus] = grid.offset
  end
  paint(drawn.lines, drawn.marks)
  place_cursor(drawn.lines, drawn.cursor)
  if drawn.anchors.portrait and not portrait_hidden then
    require("core.hud.portrait").show(state.win, portrait_file(), drawn.anchors.portrait)
  else
    require("core.hud.portrait").close()
  end
end

-- moving around --------------------------------------------------------------------------

local function focused_items()
  if state.focus == "chest" then
    return state.chest and state.chest.items or {}
  end
  if state.focus == "quest" then
    return state.quest or {}
  end
  return state.tabs[state.tab].items
end

--- The item under the cursor, in whichever pane has the focus.
---@return table|nil
function M.selected()
  return focused_items()[state.cursor[state.focus] or 1]
end

local function selected()
  return M.selected()
end

-- j off the bottom of the slots walks down into the quest, k off its top climbs back
local function cross_into_quest(direction)
  local quest = state.grids.quest
  if direction == "j" and state.focus ~= "quest" and quest and quest.count > 0 then
    state.focus, state.cursor.quest = "quest", 1
    return true
  end
  if direction == "k" and state.focus == "quest" then
    state.focus = "items"
    return true
  end
  return false
end

local function cross_panes(direction)
  if cross_into_quest(direction) then
    return true
  end
  if not state.chest or state.focus == "quest" then
    return false
  end
  if direction == "l" and state.focus == "items" and #state.chest.items > 0 then
    state.focus = "chest"
    return true
  end
  if direction == "h" and state.focus == "chest" then
    state.focus = "items"
    return true
  end
  return false
end

local function move_menu(direction)
  if direction ~= "j" and direction ~= "k" then
    return
  end
  state.menu.index =
    actions.cycle(state.menu.index, #state.menu.entries, direction == "j" and 1 or -1)
end

-- true while the last thing done on the HUD was using an item, so the HUD leaving because of it
-- does not cut the item's sound with the close one
local left_by_use = false

-- plays the HUD's own sound for a moment, or the fallback in a world that has none for it
local function sound(event, fallback)
  left_by_use = false
  require("core.sound").play_first({ event, fallback })
end

-- how long the glint takes to run along the Roundtable's selected frame
local GLINT_MS = 300

-- the new selection settles in on core/motion's clock: its description types itself in and, on the
-- Roundtable, a glint runs along its frame. Whole at once while motion is stilled, and each frame
-- redraws only when another character landed or the glint moved a cell
local settling
local function settle_selection()
  if settling then
    settling:stop()
  end
  local item = M.selected()
  local length = item and vim.fn.strchars(item.desc or "") or 0
  local typing = actions.typing_ms(length)
  local glints = style() == "roundtable" and state.focus == "items"
  local duration = math.max(typing, glints and GLINT_MS or 0)
  local shown = state
  if duration == 0 then
    state.typed, state.glint = nil, nil
    return M.refresh()
  end
  settling = require("core.motion").tween({
    duration = duration,
    easing = "linear",
    frame_ms = 32,
    on_frame = function(_, raw)
      if state ~= shown then
        return
      end
      local elapsed = raw * duration
      local typed = elapsed < typing and math.floor(elapsed / typing * length) or nil
      local glint = glints and elapsed < GLINT_MS and math.floor(elapsed / GLINT_MS * 18) / 18
        or nil
      if typed == state.typed and glint == state.glint and raw > 0 then
        return
      end
      state.typed, state.glint = typed, glint
      M.refresh()
    end,
  })
end

-- the next slot in that direction: through the attaché case's cells, or the plain grid
local function next_slot(grid, direction)
  local index = state.cursor[state.focus] or 1
  if grid.case then
    return actions.case_move(grid.case, index, direction)
  end
  return actions.grid_move(index, grid.count, grid.columns, direction)
end

local function move(direction)
  if state.menu then
    move_menu(direction)
    sound("hud_move")
    return M.refresh()
  end
  local grid = state.grids[state.focus]
  local next_index = grid and next_slot(grid, direction)
  if next_index then
    state.cursor[state.focus] = next_index
  elseif not cross_panes(direction) then
    return
  end
  sound("hud_move")
  settle_selection()
  pulse_selection()
end

local function switch_tab(step)
  state.tab = actions.cycle(state.tab, #state.tabs, step)
  state.focus, state.menu = "items", nil
  state.cursor.items, state.offset.items = 1, 0
  sound("hud_tab", "hud_move")
  settle_selection()
  pulse_tab()
end

-- using items ----------------------------------------------------------------------------

-- where the selected slot sits on screen, so a float can open beside it instead of over it
local function selection_on_screen()
  if not valid() then
    return nil
  end
  local origin = vim.api.nvim_win_get_position(state.win)
  local cursor = vim.api.nvim_win_get_cursor(state.win)
  local line = vim.api.nvim_buf_get_lines(state.buf, cursor[1] - 1, cursor[1], false)[1] or ""
  local col = vim.api.nvim_strwidth(line:sub(1, cursor[2]))
  return { row = origin[1] + cursor[1] - 1, col = origin[2] + col }
end

local function float_buffer(lines)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.api.nvim_buf_set_lines(
    buf,
    0,
    -1,
    false,
    vim.tbl_map(function(line)
      return " " .. line
    end, lines)
  )
  vim.bo[buf].modifiable = false
  return buf
end

-- the keys that close a float, and the portrait stepping aside while it is open, since the
-- terminal paints images over every window
local function close_on(buf, win, keys)
  for _, key in ipairs(keys) do
    vim.keymap.set("n", key, function()
      pcall(vim.api.nvim_win_close, win, true)
    end, { buffer = buf, nowait = true })
  end
  M.hide_portrait(true)
  vim.api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(win),
    once = true,
    callback = function()
      vim.schedule(function()
        M.hide_portrait(false)
      end)
    end,
  })
end

local function show_details(title, lines)
  if not lines or #lines == 0 then
    return
  end
  local width = 30
  for _, line in ipairs(lines) do
    width = math.max(width, vim.api.nvim_strwidth(line) + 2)
  end
  width = math.min(width, vim.o.columns - 8)
  local height = math.min(#lines, vim.o.lines - 8)
  local place = actions.float_beside(
    selection_on_screen(),
    { width = width + 2, height = height + 2 },
    { columns = vim.o.columns, lines = vim.o.lines, gap = 18 }
  )
  local buf = float_buffer(lines)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    style = "minimal",
    border = require("core.skin").border(),
    title = " " .. require("core.skin").title(title) .. " ",
    title_pos = "center",
    width = width,
    height = height,
    row = place.row,
    col = place.col,
  })
  close_on(buf, win, { "q", "<Esc>", "K" })
end

-- the head of a file, read for the safe room's file reader
local READER_HEAD = 400

local function file_head(path)
  if not path or vim.fn.filereadable(path) == 0 then
    return {}
  end
  local ok, lines = pcall(vim.fn.readfile, path, "", READER_HEAD)
  return ok and lines or {}
end

-- the safe room's file reader: the item's details and the file itself, a page at a time, turned
-- with h and l like the files of the old games
local function show_reader(title, lines)
  local width = math.min(76, vim.o.columns - 8)
  local height = math.max(6, math.min(20, vim.o.lines - 10))
  local pages = actions.pages(lines, width - 2, height)
  local page = 1
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    style = "minimal",
    border = require("core.skin").border(),
    title = " " .. require("core.skin").title(title) .. " ",
    title_pos = "center",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2) - 1,
    col = math.floor((vim.o.columns - width) / 2),
  })
  local function turn(step)
    page = actions.clamp(page + step, 1, #pages)
    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, pages[page])
    vim.bo[buf].modifiable = false
    vim.api.nvim_win_set_config(win, {
      footer = (" ◀ %d / %d ▶ "):format(page, #pages),
      footer_pos = "center",
    })
    if step ~= 0 then
      sound("hud_page", "hud_move")
    end
  end
  turn(0)
  for keys, step in pairs({ [{ "l", "<Right>", "j" }] = 1, [{ "h", "<Left>", "k" }] = -1 }) do
    for _, key in ipairs(keys) do
      vim.keymap.set("n", key, function()
        turn(step)
      end, { buffer = buf, nowait = true })
    end
  end
  close_on(buf, win, { "q", "<Esc>", "K" })
end

-- the word that floats over the Roundtable for a moment when you use an item, like an item obtained
local TOAST_MS = 900

local function toast(item)
  local word = hud_lore().used
  if style() ~= "roundtable" or not word or not item.name then
    return
  end
  local text = (" %s  ·  %s "):format(word, item.name)
  local width = vim.api.nvim_strwidth(text)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { text })
  vim.api.nvim_buf_set_extmark(buf, ns, 0, 0, { end_col = #text, hl_group = "EldenHudTitle" })
  local ok, win = pcall(vim.api.nvim_open_win, buf, false, {
    relative = "editor",
    style = "minimal",
    border = require("core.skin").border(),
    focusable = false,
    noautocmd = true,
    zindex = 250,
    width = width,
    height = 1,
    row = math.floor(vim.o.lines / 3),
    col = math.floor((vim.o.columns - width) / 2),
  })
  if ok then
    vim.defer_fn(function()
      pcall(vim.api.nvim_win_close, win, true)
    end, TOAST_MS)
  end
end

local function use(item)
  if not item or not item.use then
    return
  end
  state.menu = nil
  require("core.sound").play_first(actions.use_sounds(item))
  left_by_use = true
  toast(item)
  item.use()
  vim.schedule(function()
    M.refresh(true)
  end)
end

local function check(item)
  if not item or not item.check then
    return
  end
  sound("hud_check", "hud_select")
  -- the safe room reads every item like one of its files, the file's own lines after its details
  if style() == "inventory" then
    local lines = item.check()
    local head = file_head(item.path)
    if #head > 0 then
      vim.list_extend(lines, { "", ("─"):rep(20), "" })
      vim.list_extend(lines, head)
    end
    return show_reader(item.name, lines)
  end
  show_details(item.name, item.check())
end

local function combine(item)
  if not item or not item.combine then
    return
  end
  sound("hud_combine", "hud_select")
  local result = item.combine()
  if type(result) == "table" then
    show_details(item.name, result)
  end
end

local COMMANDS = {
  {
    label = "EQUIP",
    run = use,
    ready = function(item)
      return item.use ~= nil
    end,
  },
  {
    label = "CHECK",
    run = check,
    ready = function(item)
      return item.check ~= nil
    end,
  },
  {
    label = "COMBN",
    run = combine,
    ready = function(item)
      return item.combine ~= nil
    end,
  },
}

-- Resident Evil asks what to do with the item first, the Lands Between simply use it
local function confirm()
  local item = selected()
  if not item then
    return
  end
  if style() ~= "inventory" then
    return use(item)
  end
  if not state.menu then
    sound("hud_menu", "hud_select")
    local entries = vim.tbl_map(function(command)
      return { label = command.label, enabled = command.ready(item) }
    end, COMMANDS)
    state.menu = { index = 1, entries = entries }
    return M.refresh()
  end
  local command = COMMANDS[state.menu.index]
  state.menu = nil
  if command.ready(item) then
    command.run(item)
  else
    sound("hud_back")
  end
  M.refresh()
end

local function escape()
  if state.menu then
    state.menu = nil
    sound("hud_back")
    M.refresh()
  end
end

-- direct keys: a hub key uses its action from anywhere, digits open the chest's projects
local function use_key(key)
  for _, tab in ipairs(state.tabs) do
    for _, item in ipairs(tab.items) do
      if item.key == key and item.use then
        return use(item)
      end
    end
  end
  for _, item in ipairs(state.chest and state.chest.items or {}) do
    if item.key == key then
      return use(item)
    end
  end
end

local function map_keys(buf)
  local function map(lhs, fn)
    vim.keymap.set("n", lhs, fn, { buffer = buf, nowait = true, silent = true })
  end
  for direction, aliases in pairs({
    h = { "h", "<Left>" },
    j = { "j", "<Down>" },
    k = { "k", "<Up>" },
    l = { "l", "<Right>" },
  }) do
    for _, lhs in ipairs(aliases) do
      map(lhs, function()
        move(direction)
      end)
    end
  end
  map("?", function()
    require("core.palette").open()
  end)
  map("<Tab>", function()
    switch_tab(1)
  end)
  map("<S-Tab>", function()
    switch_tab(-1)
  end)
  map("]", function()
    switch_tab(1)
  end)
  map("[", function()
    switch_tab(-1)
  end)
  map("<CR>", confirm)
  map("<Esc>", escape)
  map("K", function()
    check(selected())
  end)
  map("C", function()
    combine(selected())
  end)
  for _, key in ipairs(require("core.hud.actions").direct_keys(require("core.hud.keys").keys())) do
    map(key, function()
      use_key(key)
    end)
  end
end

-- lifecycle ------------------------------------------------------------------------------

local function window_options(win)
  local options = {
    number = false,
    relativenumber = false,
    cursorline = false,
    cursorcolumn = false,
    signcolumn = "no",
    foldcolumn = "0",
    list = false,
    wrap = false,
    spell = false,
    colorcolumn = "",
    statuscolumn = "",
    -- the HUD is laid out to the exact window height, so nothing may scroll it to keep a margin
    scrolloff = 0,
    sidescrolloff = 0,
  }
  for option, value in pairs(options) do
    vim.wo[win][0][option] = value
  end
end

-- the mini player's bar moves on its own, so it is looked at every few seconds and the HUD redraws
-- only when another cell of the bar filled
local PLAYER_CHECK_MS = 3000
local PLAYER_CELLS = require("core.hud.views.parts").PLAYER_BAR - 1
local function follow_player()
  local shown, last
  shown = state
  return require("core.motion").loop({
    interval = PLAYER_CHECK_MS,
    on_tick = function()
      if state ~= shown then
        return false
      end
      local music = now_playing()
      local seen = music
          and table.concat({
            music.title,
            tostring(music.playing),
            tostring(actions.bar_fill(music.elapsed, music.duration, PLAYER_CELLS)),
          }, "|")
        or ""
      if last and seen ~= last then
        M.refresh()
      end
      last = seen
    end,
  })
end

local function cleanup()
  if not state then
    return
  end
  if state.player then
    state.player:stop()
  end
  require("core.hud.portrait").close()
  require("core.hub").stop()
  last_place = { style = state.style, tab = state.tab, cursor = state.cursor }
  state = nil
end

local function watch(buf)
  local group = vim.api.nvim_create_augroup("eldentree_hud_buffer", { clear = true })
  vim.api.nvim_create_autocmd("BufWipeout", { group = group, buffer = buf, callback = cleanup })
  vim.api.nvim_create_autocmd("BufWinLeave", {
    group = group,
    buffer = buf,
    callback = function()
      require("core.hud.portrait").close()
      -- quitting nvim is not closing the inventory, and an item that took you away already sounded
      if vim.v.exiting == vim.NIL and not left_by_use then
        sound("hud_close")
      end
      left_by_use = false
    end,
  })
  vim.api.nvim_create_autocmd("BufWinEnter", {
    group = group,
    buffer = buf,
    callback = function()
      M.refresh()
    end,
  })
  -- a split or the zoom shows the same buffer in another window, the layout and the portrait go with the cursor
  vim.api.nvim_create_autocmd("WinEnter", {
    group = group,
    buffer = buf,
    callback = function()
      local win = vim.api.nvim_get_current_win()
      if state and actions.follows(state.win, state.buf, win, vim.api.nvim_win_get_buf(win)) then
        window_options(win)
        M.refresh()
      end
    end,
  })
  vim.api.nvim_create_autocmd({ "VimResized", "WinResized" }, {
    group = group,
    callback = function()
      M.refresh()
    end,
  })
  -- the window the HUD was drawn in now shows something else or is closing, so the HUD and its
  -- portrait move to the window still showing it once the layout settles
  vim.api.nvim_create_autocmd({ "BufWinEnter", "WinClosed" }, {
    group = group,
    callback = function()
      vim.schedule(function()
        local still_there = state
          and vim.api.nvim_win_is_valid(state.win)
          and vim.api.nvim_win_get_buf(state.win) == state.buf
        if state and not still_there then
          M.refresh()
        end
      end)
    end,
  })
end

--- Hides the champion's portrait while something else is drawn over the HUD, and brings it back.
---@param hidden boolean
function M.hide_portrait(hidden)
  portrait_hidden = hidden
  if valid() then
    M.refresh()
  end
end

-- a float (a notification history, a picker) cannot hold the HUD, so it opens in the window the
-- float was opened from, or the first regular window of the tab
local function regular_window()
  local function regular(win)
    return vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_config(win).relative == ""
  end
  local current = vim.api.nvim_get_current_win()
  if regular(current) then
    return current
  end
  local previous = vim.fn.win_getid(vim.fn.winnr("#"))
  if previous ~= 0 and regular(previous) then
    return previous
  end
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if regular(win) then
      return win
    end
  end
  return current
end

-- the empty buffer an empty start leaves, which would stay in the tabs as [No Name] for good
local function blank_start(buf)
  if not vim.api.nvim_buf_is_valid(buf) or not vim.bo[buf].buflisted then
    return false
  end
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  return vim.api.nvim_buf_get_name(buf) == ""
    and vim.bo[buf].buftype == ""
    and not vim.bo[buf].modified
    and #lines == 1
    and lines[1] == ""
end

local function wipe_blank_start(buf)
  if blank_start(buf) and #vim.fn.win_findbuf(buf) == 0 then
    pcall(vim.api.nvim_buf_delete, buf, {})
  end
end

--- Opens the HUD in the current window, or the regular window under a focused float.
function M.open()
  if valid() then
    return M.refresh(true)
  end
  cleanup()
  local win = regular_window()
  if win ~= vim.api.nvim_get_current_win() then
    vim.api.nvim_set_current_win(win)
  end
  local replaced = vim.api.nvim_win_get_buf(win)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.api.nvim_win_set_buf(win, buf)
  wipe_blank_start(replaced)
  vim.bo[buf].filetype = "eldentree_hud"
  window_options(0)
  local tab, cursor = actions.resume_place(last_place, style())
  state = {
    buf = buf,
    win = vim.api.nvim_get_current_win(),
    style = style(),
    tab = tab,
    focus = "items",
    cursor = cursor,
    offset = { items = 0, chest = 0, quest = 0 },
    grids = {},
    anchors = {},
  }
  define_highlights()
  map_keys(buf)
  watch(buf)
  sound("hud_open")
  M.refresh(true)
  entrance()
  require("core.hub").start(buf)
  state.player = follow_player()
end

-- an empty start, no files and nothing piped in, opens the HUD instead of a blank buffer
local function open_on_start()
  if stdin_given or vim.fn.argc() > 0 then
    return
  end
  local buf = vim.api.nvim_get_current_buf()
  if vim.api.nvim_buf_get_name(buf) ~= "" or vim.api.nvim_buf_line_count(buf) > 1 then
    return
  end
  M.open()
end

function M.setup()
  local group = vim.api.nvim_create_augroup("eldentree_hud", { clear = true })
  vim.api.nvim_create_autocmd("StdinReadPre", {
    group = group,
    callback = function()
      stdin_given = true
    end,
  })
  vim.api.nvim_create_autocmd("VimEnter", { group = group, callback = open_on_start })
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = group,
    callback = function()
      define_highlights()
      M.refresh()
    end,
  })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "EldentreeFranchise",
    callback = function()
      if not valid() then
        return
      end
      define_highlights()
      M.refresh(true)
    end,
  })
  -- a new song, or the same one paused, shows on the mini player right away
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "EldentreeMusicChanged",
    callback = function()
      M.refresh()
    end,
  })
  vim.api.nvim_create_user_command("Hud", M.open, { desc = "Open the inventory HUD" })
end

return M
