-- The Roundtable Hold breathing: a light sweeping across the gold headers, embers rising
-- through the empty space, and a player message that writes itself in. Times are milliseconds.
local M = {}

local function lore()
  return require("core.franchise").current()
end

-- how often a line another world lent this one is read instead of its own
M.GUEST_CHANCE = 0.15

--- Picks the message the quill writes on the hub: the region's own lines when it has them (so a
--- role only speaks of its own character), else the franchise's, now and then a line another
--- world lent it (lore.hud.guest_messages).
---@param rand fun(): number random number from 0 to 1
---@param from table|nil the lore to read, the franchise in use by default
---@param region table|nil the region in use, its hub_messages win over the lore's
---@return string
function M.pick_message(rand, from, region)
  from = from or lore()
  local guests = (from.hud or {}).guest_messages or {}
  local own = region and region.hub_messages
  local messages = (own and #own > 0) and own or from.hub_messages
  if #guests > 0 and rand() < M.GUEST_CHANCE then
    messages = guests
  end
  return messages[math.floor(rand() * #messages) + 1]
end

-- "Malenia" becomes "M  A  L  E  N  I  A", the same carved look the old title had
function M.spaced(name)
  local letters = {}
  for letter in name:upper():gmatch(".") do
    table.insert(letters, letter)
  end
  return table.concat(letters, "  ")
end

M.SHIMMER_LEVELS = 6
M.SHIMMER = { period = 5200, sweep = 1800, band = 9, skew = 2 }

-- a diagonal band of light crossing the screen once per period, quiet in between
function M.shimmer_level(col, row, elapsed, span)
  local s = M.SHIMMER
  local into = elapsed % s.period
  if into > s.sweep then
    return 0
  end
  local travel = span + s.band * 2 + s.skew * 40
  local position = -s.band + travel * (into / s.sweep)
  local distance = math.abs(col + row * s.skew - position)
  local intensity = math.max(0, 1 - distance / s.band)
  return math.floor(intensity * intensity * M.SHIMMER_LEVELS + 0.5)
end

M.EMBER_LEVELS = 5

--- Returns the weather for a region, the first region's sky when it has none.
---@param name string|nil region name
---@return table weather as { glyphs, drift, speed, from, to }
function M.weather(name)
  local weather = lore().weather
  return weather[name] or weather[lore().regions[1].name]
end

-- where a particle is born for each kind of drift, as a fraction of the height from the top
local function birth_row(drift, rand, height)
  if drift == "fall" then
    return rand() * height * 0.25
  end
  if drift == "float" then
    return rand() * (height - 1)
  end
  return height - 1 - rand() * height * 0.25
end

-- rows per second toward the top, so falling weather is negative
local function climb(weather, rand)
  local low, high = weather.speed[1], weather.speed[2]
  local speed = low + rand() * (high - low)
  return weather.drift == "fall" and -speed or speed
end

function M.spawn_ember(rand, width, height, weather)
  weather = weather or M.weather()
  local life = 2600 + rand() * 3400
  return {
    x = rand() * width,
    y = birth_row(weather.drift, rand, height),
    rise = climb(weather, rand),
    phase = rand() * math.pi * 2,
    sway = 0.4 + rand() * 1.1,
    age = 0,
    life = life,
    floor = height,
  }
end

function M.step_ember(ember, dt)
  ember.age = ember.age + dt
  ember.y = ember.y - ember.rise * dt / 1000
  ember.x = ember.x + math.sin(ember.phase + ember.age / 480) * ember.sway * dt / 1000
  return ember
end

function M.ember_alive(ember)
  local on_screen = ember.y >= 0 and (not ember.floor or ember.y < ember.floor)
  return on_screen and ember.age < ember.life
end

-- embers flare up as they leave the ground and cool to ash before they vanish
function M.ember_look(ember, weather)
  local glyphs = (weather or M.weather()).glyphs
  local t = ember.age / ember.life
  local heat = t < 0.15 and t / 0.15 or 1 - (t - 0.15) / 0.85
  local level = math.max(1, math.min(M.EMBER_LEVELS, math.ceil(heat * M.EMBER_LEVELS)))
  local glyph = glyphs[math.max(1, math.min(#glyphs, math.ceil(heat * #glyphs)))]
  return glyph, level
end

function M.ember_budget(width, height)
  return math.max(6, math.min(40, math.floor(width * height / 220)))
end

M.QUILL = { delay = 700, per_char = 42, blink = 530, linger = 2400 }

-- how many characters of the message are written so far
function M.typed(length, elapsed)
  local q = M.QUILL
  return math.max(0, math.min(length, math.floor((elapsed - q.delay) / q.per_char)))
end

-- the quill blinks while writing and for a moment after, then lifts off the page
function M.quill_visible(length, elapsed)
  local q = M.QUILL
  if elapsed < q.delay then
    return math.floor(elapsed / q.blink) % 2 == 0
  end
  local finished_at = q.delay + length * q.per_char
  if elapsed < finished_at then
    return true
  end
  if elapsed > finished_at + q.linger then
    return false
  end
  return math.floor((elapsed - finished_at) / q.blink) % 2 == 0
end

function M.quill_done(length, elapsed)
  return elapsed > M.QUILL.delay + length * M.QUILL.per_char + M.QUILL.linger
end

--- Which screen columns hold something other than blank space, given { char, width } cells, plus
--- a margin on both sides of every mark so the weather never lands in the gaps inside a word.
---@param cells { [1]: string, [2]: integer }[]
---@param margin integer|nil blank cells kept clear around text, none by default
---@return table<integer, boolean>
function M.occupied(cells, margin)
  margin = margin or 0
  local taken, col = {}, 0
  for _, cell in ipairs(cells) do
    if cell[1] ~= " " then
      for offset = -margin, cell[2] - 1 + margin do
        taken[col + offset] = true
      end
    end
    col = col + cell[2]
  end
  return taken
end

-- the marquee bulbs: how long each step of the chase lasts and how many bulbs share one light
M.BULB_STEP_MS = 180
M.BULB_EVERY = 3

--- Tells whether a marquee bulb is lit at a moment, the light stepping along every row of bulbs
--- and starting one bulb later on each row, so the ring reads as one chase.
---@param index integer the bulb's place along its row, from 1
---@param row integer the buffer row, from 1
---@param elapsed number milliseconds since the hub came to life
---@return boolean
function M.bulb_lit(index, row, elapsed)
  local step = math.floor(elapsed / M.BULB_STEP_MS)
  return (index + row - step) % M.BULB_EVERY == 0
end

return M
