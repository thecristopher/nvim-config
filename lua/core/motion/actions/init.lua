-- Easing curves and color interpolation shared by every Eldentree animation.
-- Colors here are the 24 bit integers nvim_get_hl hands back, not hex strings.
local M = {}

M.easings = {
  linear = function(t)
    return t
  end,
  out_cubic = function(t)
    return 1 - (1 - t) ^ 3
  end,
  in_cubic = function(t)
    return t ^ 3
  end,
  in_out_sine = function(t)
    return -(math.cos(math.pi * t) - 1) / 2
  end,
  out_expo = function(t)
    return t >= 1 and 1 or 1 - 2 ^ (-10 * t)
  end,
}

function M.ease(name, t)
  return (M.easings[name] or M.easings.linear)(M.progress(t, 1))
end

-- how far through an animation we are, clamped so late timer ticks never overshoot
function M.progress(elapsed, duration)
  if duration <= 0 then
    return 1
  end
  return math.max(0, math.min(1, elapsed / duration))
end

function M.mix(from, to, t)
  local function channel(color, shift)
    return math.floor(color / 2 ^ shift) % 256
  end
  local function lerp(shift)
    return math.floor(channel(from, shift) + (channel(to, shift) - channel(from, shift)) * t + 0.5)
  end
  return lerp(16) * 65536 + lerp(8) * 256 + lerp(0)
end

local COLOR_KEYS = { "fg", "bg", "sp" }

-- a highlight group partway between two snapshots; everything but colors snaps to the target
function M.mix_hl(from, to, t)
  local attrs = vim.deepcopy(to)
  if not from or from.link or to.link then
    return attrs
  end
  for _, key in ipairs(COLOR_KEYS) do
    if from[key] and to[key] then
      attrs[key] = M.mix(from[key], to[key], t)
    end
  end
  return attrs
end

-- only groups whose colors actually move are worth repainting every frame
function M.changed_groups(before, after)
  local names = {}
  for name, to in pairs(after) do
    local from = before[name]
    if from and not from.link and not to.link then
      for _, key in ipairs(COLOR_KEYS) do
        if from[key] and to[key] and from[key] ~= to[key] then
          table.insert(names, name)
          break
        end
      end
    end
  end
  table.sort(names)
  return names
end

function M.to_int(hex)
  return tonumber(hex:sub(2), 16)
end

function M.to_hex(color)
  return ("#%06X"):format(color)
end

return M
