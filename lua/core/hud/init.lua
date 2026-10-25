-- The HUD: the start screen dressed as the franchise's inventory. A cursor walks the slots with hjkl,
-- Tab changes category, Enter uses the item (or opens the COMMAND menu in Resident Evil), K checks it
-- and C combines it. The hub's ambient life (shimmer, weather, the quill) runs on top of it.
local actions = require("core.hud.actions")
local items = require("core.hud.items")
local motion = require("core.motion")

local M = {}

local ns = vim.api.nvim_create_namespace("eldentree_hud")
local ecg_ns = vim.api.nvim_create_namespace("eldentree_hud_ecg")
local state
local stdin_given = false

local function style()
  return require("core.franchise").current().skin.dashboard
end

local function view()
  return require("core.hud.views." .. (style() == "inventory" and "inventory" or "roundtable"))
end

local function valid()
  return state
    and vim.api.nvim_buf_is_valid(state.buf)
    and vim.api.nvim_win_is_valid(state.win)
    and vim.api.nvim_win_get_buf(state.win) == state.buf
end

-- highlights -----------------------------------------------------------------------------

local function define_highlights()
  local p = require("core.themes").palette()
  local blend = require("core.themes.actions").blend
  local plates = style() == "inventory"
  local groups = {
    EldenHudTitle = { fg = p.yellow, bold = true },
    EldenHudTab = plates and { fg = p.subtext0, bg = p.surface1 } or { fg = p.overlay1 },
    EldenHudTabSel = plates and { fg = p.base, bg = p.yellow, bold = true }
      or { fg = p.yellow, bold = true },
    EldenHudRule = { fg = p.surface2 },
    EldenHudRuleSel = { fg = p.yellow },
    EldenHudSection = { fg = p.subtext0, italic = true },
    EldenHudName = { fg = p.text, bold = true },
    EldenHudDim = { fg = p.overlay0 },
    EldenHudFrame = { fg = p.overlay0 },
    EldenHudFrameSel = { fg = p.yellow, bold = true },
    EldenHudSlotSel = { bg = blend(p.yellow, p.base, 0.16) },
    EldenHudIcon = { fg = p.text },
    EldenHudKey = { fg = p.rosewater, bold = true },
    EldenHudCount = { fg = p.subtext1 },
    EldenHudDesc = { fg = p.subtext0 },
    EldenHudHint = { fg = p.overlay1 },
    EldenHudBanner = { fg = p.yellow, bold = true },
  }
  for name, look in pairs(groups) do
    vim.api.nvim_set_hl(0, name, look)
  end
  for _, look in pairs(require("core.ecg.actions").CONDITIONS) do
    vim.api.nvim_set_hl(0, "EldenHudEcg" .. look.label, { fg = p[look.color], bold = true })
  end
end

-- model ----------------------------------------------------------------------------------

local function status()
  local region = require("core.themes").current()
  local last = require("core.results").last()
  return vim.tbl_extend("force", items.quest(), {
    character = region.character,
    area = region.title,
    purse = require("core.runes").held(),
    last_run = last and ("Rank %s  ·  %s"):format(
      last.rank,
      require("core.results.actions").duration(last.seconds)
    ) or nil,
  })
end

local function greeting()
  local hour = tonumber(os.date("%H"))
  local part = hour < 5 and "The night is long"
    or hour < 12 and "Good morning"
    or hour < 18 and "Good afternoon"
    or "Good evening"
  return part .. ", " .. require("core.franchise").current().words.traveler
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

local function portrait_file()
  return vim.fn.stdpath("config")
    .. "/images/portraits/"
    .. require("core.themes").current().portrait
end

-- a region without its portrait yet, or a terminal that can draw neither pixels nor chafa, goes without
local function portrait_available()
  if vim.fn.filereadable(portrait_file()) == 0 then
    return false
  end
  return vim.fn.executable("chafa") == 1 or require("core.terminal").supports_images()
end

local function model()
  local quest_status = status()
  state.quest = items.quest_items(quest_status)
  -- the changes arrive and leave with git, the cursor never points past them
  state.cursor.quest = math.max(1, math.min(state.cursor.quest or 1, #state.quest))
  if state.focus == "quest" and #state.quest == 0 then
    state.focus = "items"
  end
  local region = require("core.themes").current()
  local words = require("core.franchise").current().words
  return {
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
    stats = state.stats,
    portrait = portrait_available(),
    status = quest_status,
    selected = M.selected(),
  }
end

-- drawing --------------------------------------------------------------------------------

local function draw_ecg()
  if not valid() or not state.anchors.ecg then
    return
  end
  local anchor = state.anchors.ecg
  local trace, label = require("core.ecg").reading()
  vim.api.nvim_buf_clear_namespace(state.buf, ecg_ns, 0, -1)
  vim.api.nvim_buf_set_extmark(state.buf, ecg_ns, anchor.row, 0, {
    virt_text = { { trace, "EldenHudEcg" .. label }, { "  " .. label, "EldenHudEcg" .. label } },
    virt_text_win_col = anchor.col,
    priority = 250,
  })
end

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
  if drawn.anchors.portrait then
    require("core.hud.portrait").show(state.win, portrait_file(), drawn.anchors.portrait)
  else
    require("core.hud.portrait").close()
  end
  draw_ecg()
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

local function move(direction)
  if state.menu then
    move_menu(direction)
    return M.refresh()
  end
  local grid = state.grids[state.focus]
  local next_index = grid
    and actions.grid_move(state.cursor[state.focus] or 1, grid.count, grid.columns, direction)
  if next_index then
    state.cursor[state.focus] = next_index
  elseif not cross_panes(direction) then
    return
  end
  M.refresh()
end

local function switch_tab(step)
  state.tab = actions.cycle(state.tab, #state.tabs, step)
  state.focus, state.menu = "items", nil
  state.cursor.items, state.offset.items = 1, 0
  M.refresh()
end

-- using items ----------------------------------------------------------------------------

local function show_details(title, lines)
  if not lines or #lines == 0 then
    return
  end
  local width = 30
  for _, line in ipairs(lines) do
    width = math.max(width, vim.api.nvim_strwidth(line) + 2)
  end
  width = math.min(width, vim.o.columns - 8)
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
  local height = math.min(#lines, vim.o.lines - 8)
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
  for _, key in ipairs({ "q", "<Esc>", "K" }) do
    vim.keymap.set("n", key, function()
      pcall(vim.api.nvim_win_close, win, true)
    end, { buffer = buf, nowait = true })
  end
end

local function use(item)
  if not item or not item.use then
    return
  end
  state.menu = nil
  item.use()
  vim.schedule(function()
    M.refresh(true)
  end)
end

local function check(item)
  if item and item.check then
    show_details(item.name, item.check())
  end
end

local function combine(item)
  if not item or not item.combine then
    return
  end
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
  end
  M.refresh()
end

local function escape()
  if state.menu then
    state.menu = nil
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
  for _, key in ipairs({
    "f",
    "g",
    "r",
    "p",
    "e",
    "o",
    "n",
    "s",
    "t",
    "c",
    "L",
    "m",
    "q",
    "a",
    "1",
    "2",
    "3",
    "4",
    "5",
    "6",
    "7",
    "8",
    "9",
  }) do
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

local function cleanup()
  if not state then
    return
  end
  if state.monitor then
    state.monitor:stop()
  end
  require("core.hud.portrait").close()
  require("core.hub").stop()
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
    end,
  })
  vim.api.nvim_create_autocmd("BufWinEnter", {
    group = group,
    buffer = buf,
    callback = function()
      M.refresh()
    end,
  })
  vim.api.nvim_create_autocmd({ "VimResized", "WinResized" }, {
    group = group,
    callback = function()
      M.refresh()
    end,
  })
end

--- Opens the HUD in the current window.
function M.open()
  if valid() then
    return M.refresh(true)
  end
  cleanup()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.api.nvim_win_set_buf(0, buf)
  vim.bo[buf].filetype = "eldentree_hud"
  window_options(0)
  state = {
    buf = buf,
    win = vim.api.nvim_get_current_win(),
    tab = 1,
    focus = "items",
    cursor = { items = 1, chest = 1, quest = 1 },
    offset = { items = 0, chest = 0, quest = 0 },
    grids = {},
    anchors = {},
  }
  define_highlights()
  map_keys(buf)
  watch(buf)
  M.refresh(true)
  require("core.hub").start(buf)
  -- the CONDITION monitor beats on its own, the rest of the HUD only redraws when something moves
  state.monitor = motion.loop({
    interval = 120,
    on_tick = function()
      if not valid() then
        return false
      end
      draw_ecg()
    end,
  })
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
  vim.api.nvim_create_user_command("Hud", M.open, { desc = "Open the inventory HUD" })
end

return M
