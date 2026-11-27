-- The voice studio: a role cast with a Fish Audio voice (`voice` in the lore's script.lua) says its
-- takes out loud. Cached takes play at once, a share of moments voice one nobody has heard yet,
-- a baker caches the script ahead of time while the budget allows, and once every take is cached
-- a writer asks Claude for fresh ones in moderation. Drama 3 voices while the daily cap and the
-- balance allow it, the free model after that. :Voice local stops every call to Fish Audio and
-- plays only what is cached, :Voice live brings them back. vim.g.eldentree_studio = false skips it.
local actions = require("core.voice.studio.actions")
local budget = require("core.voice.studio.actions.budget")
local fish = require("core.voice.studio.fish")
local store = require("core.voice.studio.store")
local voice_actions = require("core.voice.actions")

local M = {}

-- how often the baker caches the next take, slow enough to stay a background chore
local BAKE_EVERY_MS = 20000
-- how old the known balance may get before the wallet is read again
local BALANCE_TTL_S = 1800

local last_take = nil
local baking = false
local timer = nil

local function limits()
  return budget.limits({
    daily = vim.g.eldentree_studio_daily,
    floor = vim.g.eldentree_studio_floor,
    writes = vim.g.eldentree_studio_writes,
  })
end

local function enabled()
  return vim.g.eldentree_studio ~= false
end

-- every moment in the order the script reads, the ones a role has takes for
local function order(takes)
  local all = vim.list_extend(vim.deepcopy(voice_actions.MOMENTS), voice_actions.SPOKEN)
  return vim.tbl_filter(function(moment)
    return takes[moment] ~= nil
  end, all)
end

-- the script takes recorded by hand in the repo's voice folder, take to the clip's path
local function recorded(region, takes)
  local dir = require("core.sound").folder() .. "/voices/" .. region.name
  local ok, files = pcall(vim.fn.readdir, dir)
  if not ok then
    return {}
  end
  local found = actions.recorded(takes, files, require("core.sound.actions").EXTENSIONS)
  return vim.tbl_map(function(file)
    return dir .. "/" .. file
  end, found)
end

---The role a region plays in the studio, nil when the franchise has no script for it.
---@param region table a region from core.themes
---@return table|nil role { key, franchise, character, world, bond, voice, takes, order, recorded }
function M.role(region)
  local franchise = require("core.franchise")
  local lore = franchise.current()
  local script = (lore.script or {})[region.name]
  if not script then
    return nil
  end
  return {
    key = franchise.name() .. "/" .. region.name,
    franchise = franchise.name(),
    character = region.character,
    world = region.title or lore.title,
    bond = lore.coach and lore.coach.bond or nil,
    voice = script.voice,
    takes = script.takes or {},
    order = order(script.takes or {}),
    recorded = recorded(region, script.takes or {}),
  }
end

-- the audio a take has: the clip recorded in the repo first, then the cache
local function audio(role, text)
  return role.recorded[text] or store.cached(role.voice, text)
end

-- writes what a voicing cost into the ledger read again now, so a balance read meanwhile survives
local function settle(model, text, outcome)
  local ledger = store.ledger()
  if outcome == "ok" and model == budget.PAID then
    ledger = budget.spend(ledger, #text)
  elseif outcome == "broke" then
    ledger.broke = ledger.day
  end
  store.save_ledger(ledger)
end

---Voices a take with the model the budget allows, falling back to the free one when the account
---has no credit, and hands the cached path over.
---@param role table
---@param text string
---@param cb fun(path: string|nil)
local function voice_take(role, text, cb)
  local key = store.key()
  if not key then
    return cb(nil)
  end
  local model = budget.model(store.ledger(), #text, limits())
  local out = store.path(role.voice, model, text)
  fish.voice(
    { key = key, voice = role.voice, model = model, text = text, out = out },
    function(outcome)
      settle(model, text, outcome)
      if outcome == "broke" and model == budget.PAID then
        return voice_take(role, text, cb)
      end
      cb(outcome == "ok" and out or nil)
    end
  )
end

local function live()
  return enabled() and store.ledger().mode == "live" and store.key() ~= nil
end

local function speakable(vars)
  if not (vars and vars.branch) then
    return vars
  end
  return vim.tbl_extend("force", vars, { branch = actions.speakable_branch(vars.branch) })
end

---Says a moment out loud in the role's cast voice: a cached take at once, or one nobody has heard
---voiced on the spot. Returns the words to show, nil when the studio has nothing to say so the
---recorded clips and the written lines take over.
---@param region table a region from core.themes
---@param moment string
---@param vars table<string, string>|nil
---@return string|nil
function M.perform(region, moment, vars)
  local role = enabled() and M.role(region)
  if not (role and role.voice and require("core.sound").audible()) then
    return nil
  end
  local fresh = (store.library()[role.key] or {})[moment]
  local lines = actions.pool(role.takes[moment], fresh, speakable(vars))
  local cached = {}
  for _, line in ipairs(lines) do
    cached[line] = audio(role, line)
  end
  local take, voice_first = actions.choose(lines, cached, {
    roll = math.random(),
    fresh_roll = math.random(),
    last = last_take,
    can_voice = live(),
  })
  if not take then
    return nil
  end
  last_take = take
  if not voice_first then
    require("core.sound").speak(cached[take])
    return actions.plain(take)
  end
  voice_take(role, take, function(path)
    if path then
      require("core.sound").speak(path)
    end
  end)
  return actions.plain(take)
end

local function refresh_balance(force)
  local key = store.key()
  local ledger = store.ledger()
  if
    not key or (not force and ledger.balance_at and os.time() - ledger.balance_at < BALANCE_TTL_S)
  then
    return
  end
  fish.balance(key, function(balance)
    if not balance then
      return
    end
    local fresh = store.ledger()
    fresh.balance, fresh.balance_at = balance, os.time()
    store.save_ledger(fresh)
  end)
end

-- asks Claude for fresh takes for a role, once its script and fresh takes are all cached
local function write_more(role)
  local ledger = store.ledger()
  if require("core.voice.studio.writer").busy() or not budget.writer_due(ledger, limits()) then
    return
  end
  ledger.writes = (ledger.writes or 0) + 1
  store.save_ledger(ledger)
  require("core.voice.studio.writer").write(role, function() end)
end

-- caches the role's next take with the paid model, or writes more when every take is cached
local function bake_next(role)
  local fresh = store.library()[role.key] or {}
  local take = actions.next_to_bake(role.order, role.takes, fresh, function(text)
    return role.recorded[text] ~= nil or store.has_paid(role.voice, text)
  end)
  if not take then
    return write_more(role)
  end
  if not budget.paid_allowed(store.ledger(), #take, limits()) then
    return
  end
  baking = true
  voice_take(role, take, function()
    baking = false
  end)
end

local function bake_tick()
  if baking or not live() or #vim.api.nvim_list_uis() == 0 then
    return
  end
  refresh_balance(false)
  local role = M.role(require("core.themes").current())
  if role and role.voice then
    bake_next(role)
  end
end

---Starts the baker that caches takes in the background.
function M.start()
  if timer or not enabled() then
    return
  end
  timer = vim.uv.new_timer()
  timer:start(BAKE_EVERY_MS, BAKE_EVERY_MS, vim.schedule_wrap(bake_tick))
end

---Sets how the studio reaches Fish Audio: live voices new takes, local plays only what is cached.
---@param mode "live"|"local"
function M.set_mode(mode)
  local ledger = store.ledger()
  ledger.mode = mode
  store.save_ledger(ledger)
end

---Writes fresh takes for the region in use right now, whatever today's count.
---@param cb fun(added: integer)
function M.write_now(cb)
  local role = M.role(require("core.themes").current())
  if not role then
    return cb(0)
  end
  require("core.voice.studio.writer").write(role, cb)
end

---The studio's state for the region in use: mode, money and how much of the role is voiced.
---@return string[]
function M.status()
  local ledger = store.ledger()
  local lines = {
    ("Mode: %s%s"):format(ledger.mode, store.key() and "" or " (no Fish Audio key)"),
    ("Spent today: $%.3f of $%.2f, this month $%.3f"):format(
      ledger.spent or 0,
      limits().daily,
      ledger.month_spent or 0
    ),
    ("Balance: %s"):format(ledger.balance and ("$%.2f"):format(ledger.balance) or "unknown"),
    ("Model now: %s"):format(budget.model(ledger, 120, limits())),
  }
  local role = M.role(require("core.themes").current())
  if not (role and role.voice) then
    return vim.list_extend(lines, { "This role has no cast voice yet" })
  end
  local fresh = store.library()[role.key] or {}
  local voiced, total = actions.coverage(role.takes, fresh, function(text)
    return audio(role, text) ~= nil
  end)
  return vim.list_extend(lines, {
    ("%s: %d of %d takes voiced"):format(role.character, voiced, total),
    ("Fresh takes written today: %d of %d runs"):format(ledger.writes or 0, limits().writes),
  })
end

---Reads the balance now and starts the baker.
function M.setup()
  if not enabled() then
    return
  end
  vim.defer_fn(function()
    require("core.voice.studio.prune").daily()
    refresh_balance(true)
    M.start()
  end, 15000)
  require("core.voice.studio.command").setup()
end

return M
