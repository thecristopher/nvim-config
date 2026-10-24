-- The Roundtable Hold breathing: a light sweeping across the gold headers, embers rising
-- through the empty space, and a player message that writes itself in. Times are milliseconds.
local M = {}

-- appraisals not included, you will have to imagine the "Good" count yourself
M.MESSAGES = {
  "Try refactoring, but hole",
  "Praise the green test!",
  "Be wary of null",
  "Liar ahead: TODO",
  "Could this be a race condition?",
  "If only I had a type system...",
  "Merge conflict ahead, therefore try retreat",
  "Visions of production...",
  "Time for git blame",
  "Hidden path ahead: the README",
  "Be wary of Friday deploys",
  "Praise the linter!",
  "Ahh, regex...",
  "Behold, legacy code!",
  "Seek :help",
  "Didn't expect an off by one...",
  "Guidance of grace shall lead the way",
  "Rise, and let grace light your path",
  "Fear not the stack trace, Tarnished",
  "Seek the lands between your functions",
}

function M.pick_message(rand)
  return M.MESSAGES[math.floor(rand() * #M.MESSAGES) + 1]
end

-- "Malenia" becomes "M  A  L  E  N  I  A", the same carved look the old title had
function M.spaced(name)
  local letters = {}
  for letter in name:upper():gmatch(".") do table.insert(letters, letter) end
  return table.concat(letters, "  ")
end

M.SHIMMER_LEVELS = 6
M.SHIMMER = { period = 5200, sweep = 1800, band = 9, skew = 2 }

-- a diagonal band of light crossing the screen once per period, quiet in between
function M.shimmer_level(col, row, elapsed, span)
  local s = M.SHIMMER
  local into = elapsed % s.period
  if into > s.sweep then return 0 end
  local travel = span + s.band * 2 + s.skew * 40
  local position = -s.band + travel * (into / s.sweep)
  local distance = math.abs(col + row * s.skew - position)
  local intensity = math.max(0, 1 - distance / s.band)
  return math.floor(intensity * intensity * M.SHIMMER_LEVELS + 0.5)
end

M.EMBER_LEVELS = 5
M.EMBER_GLYPHS = { "·", "∙", "•" }

-- each region has its own sky: drift says where particles travel, speed is rows per second,
-- from and to are the palette slots a particle glows between as it heats up
M.WEATHER = {
  leyndell     = { glyphs = M.EMBER_GLYPHS,      drift = "rise",  speed = { 1.6, 4.0 }, from = "peach",    to = "yellow" },
  haligtree    = { glyphs = { "·", "✿", "❀" },   drift = "fall",  speed = { 0.8, 2.0 }, from = "red",      to = "yellow" },
  raya_lucaria = { glyphs = { "·", "✧", "✦" },   drift = "float", speed = { 0.2, 0.6 }, from = "lavender", to = "yellow" },
  caelid       = { glyphs = { "·", "∙", "•" },   drift = "rise",  speed = { 3.0, 6.0 }, from = "red",      to = "peach" },
  mohgwyn      = { glyphs = { "·", "•", "●" },   drift = "fall",  speed = { 2.5, 5.0 }, from = "maroon",   to = "yellow" },
  ordina       = { glyphs = { "·", "∗", "❄" },   drift = "fall",  speed = { 0.6, 1.6 }, from = "overlay2", to = "text" },
  limgrave     = { glyphs = { "·", "∙", "❦" },   drift = "fall",  speed = { 0.8, 2.2 }, from = "peach",    to = "yellow" },
  stormveil    = { glyphs = { "·", "╎", "│" },   drift = "fall",  speed = { 9.0, 15.0 }, from = "overlay2", to = "sky" },
  volcano_manor = { glyphs = { "·", "•", "●" },  drift = "rise",  speed = { 2.5, 5.5 }, from = "red",      to = "yellow" },
  nokron       = { glyphs = { "·", "✧", "✦" },   drift = "float", speed = { 0.1, 0.4 }, from = "overlay2", to = "yellow" },
  farum_azula  = { glyphs = { "·", "✧", "ϟ" },   drift = "float", speed = { 0.3, 0.9 }, from = "lavender", to = "yellow" },
}

--- Returns the weather for a region, the golden embers of Leyndell when it has none.
---@param name string|nil region name
---@return table weather
function M.weather(name)
  return M.WEATHER[name] or M.WEATHER.leyndell
end

-- where a particle is born for each kind of drift, as a fraction of the height from the top
local function birth_row(drift, rand, height)
  if drift == "fall" then return rand() * height * 0.25 end
  if drift == "float" then return rand() * (height - 1) end
  return height - 1 - rand() * height * 0.25
end

-- rows per second toward the top, so falling weather is negative
local function climb(weather, rand)
  local low, high = weather.speed[1], weather.speed[2]
  local speed = low + rand() * (high - low)
  return weather.drift == "fall" and -speed or speed
end

function M.spawn_ember(rand, width, height, weather)
  weather = weather or M.WEATHER.leyndell
  local life = 2600 + rand() * 3400
  return {
    x       = rand() * width,
    y       = birth_row(weather.drift, rand, height),
    rise    = climb(weather, rand),
    phase   = rand() * math.pi * 2,
    sway    = 0.4 + rand() * 1.1,
    age     = 0,
    life    = life,
    floor   = height,
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
  local glyphs = (weather or M.WEATHER.leyndell).glyphs
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
  if elapsed < q.delay then return math.floor(elapsed / q.blink) % 2 == 0 end
  local finished_at = q.delay + length * q.per_char
  if elapsed < finished_at then return true end
  if elapsed > finished_at + q.linger then return false end
  return math.floor((elapsed - finished_at) / q.blink) % 2 == 0
end

function M.quill_done(length, elapsed)
  return elapsed > M.QUILL.delay + length * M.QUILL.per_char + M.QUILL.linger
end

-- which screen columns hold something other than blank space, given { char, width } cells
function M.occupied(cells)
  local taken, col = {}, 0
  for _, cell in ipairs(cells) do
    if cell[1] ~= " " then
      for offset = 0, cell[2] - 1 do taken[col + offset] = true end
    end
    col = col + cell[2]
  end
  return taken
end

return M
