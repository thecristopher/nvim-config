-- Lowers Apple Music while a character's spoken line plays and brings it back up after, so the
-- voice is heard clearly. Follows core/sound's User EldentreeVoiceStarted and EldentreeVoiceEnded.
-- vim.g.eldentree_music_duck = false leaves the music alone.
local actions = require("core.music.actions.duck")

local M = {}

-- the volume before the voice, nil while the music is not lowered
local saved = nil
-- every duck and every restore takes a new number, so a late answer or step knows it is stale
local generation = 0

local function set_volume(volume)
  pcall(vim.system, actions.set_volume_command(volume))
end

local function playing_in_music()
  local track, source = require("core.music").now_playing()
  return source == "music" and track ~= nil and track.playing
end

local function enabled()
  return vim.g.eldentree_music_duck ~= false and vim.fn.has("mac") == 1
end

---Lowers the music for a voice that just started, keeping its volume to bring it back.
function M.duck()
  generation = generation + 1
  if saved then
    -- a restore was on its way, the new voice takes the music back down
    return set_volume(actions.lowered(saved))
  end
  if not enabled() or not playing_in_music() then
    return
  end
  local asked = generation
  pcall(
    vim.system,
    actions.volume_command(),
    { text = true },
    vim.schedule_wrap(function(result)
      local volume = actions.parse_volume(result.stdout)
      -- the voice may already be over, or another duck took over, by the time Music answers
      if asked ~= generation or saved or not volume or volume == 0 then
        return
      end
      saved = volume
      set_volume(actions.lowered(volume))
    end)
  )
end

local function climb(volumes, step, mine)
  if mine ~= generation or not saved then
    return
  end
  set_volume(volumes[step])
  if step == #volumes then
    saved = nil
    return
  end
  vim.defer_fn(function()
    climb(volumes, step + 1, mine)
  end, actions.RESTORE_STEP_MS)
end

---Brings the music back to where it was, gently, unless another voice started meanwhile.
function M.restore()
  -- a line cut by the next one ends after the next one started, the music stays down for it
  if require("core.sound").speaking() then
    return
  end
  generation = generation + 1
  local mine = generation
  vim.defer_fn(function()
    if mine ~= generation or not saved or require("core.sound").speaking() then
      return
    end
    local volumes = actions.ramp(actions.lowered(saved), saved, actions.RESTORE_STEPS)
    climb(volumes, 1, mine)
  end, actions.RESTORE_DELAY_MS)
end

---Puts the volume back at once, for nvim closing while the music is lowered.
function M.release()
  if not saved then
    return
  end
  generation = generation + 1
  pcall(function()
    vim.system(actions.set_volume_command(saved)):wait(1000)
  end)
  saved = nil
end

function M.setup()
  local group = vim.api.nvim_create_augroup("eldentree_music_duck", { clear = true })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "EldentreeVoiceStarted",
    callback = M.duck,
  })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "EldentreeVoiceEnded",
    callback = M.restore,
  })
  vim.api.nvim_create_autocmd("VimLeavePre", { group = group, callback = M.release })
end

return M
