-- Summons the phantom of whoever last wrote the line under the cursor: blue for other Tarnished,
-- gold for your own past self. It fades in beside the line and vanishes as soon as you move.
local actions = require("core.phantom.actions")
local motion = require("core.motion")

local M = {}

local current
local me

local function define_highlights()
  local p = require("core.themes").palette()
  vim.api.nvim_set_hl(0, "EldenPhantom", { fg = p.subtext1, bg = p.mantle })
  vim.api.nvim_set_hl(0, "EldenPhantomSummary", { fg = p.text, bg = p.mantle, italic = true })
  vim.api.nvim_set_hl(0, "EldenPhantomOther", { fg = p.sky, bg = p.mantle, bold = true })
  vim.api.nvim_set_hl(0, "EldenPhantomSelf", { fg = p.yellow, bg = p.mantle, bold = true })
  vim.api.nvim_set_hl(0, "EldenPhantomUnwritten", { fg = p.overlay2, bg = p.mantle, bold = true })
end

local KIND_GROUPS =
  { other = "EldenPhantomOther", self = "EldenPhantomSelf", unwritten = "EldenPhantomUnwritten" }

--- Sends the current phantom away.
function M.dismiss()
  if not current then
    return
  end
  if current.fade then
    current.fade:stop()
  end
  pcall(vim.api.nvim_win_close, current.win, true)
  current = nil
end

-- who you are to git, asked once per session
local function identity(dir)
  if me then
    return me
  end
  local function config(key)
    local result = vim.system({ "git", "-C", dir, "config", key }, { text = true }):wait()
    return result.code == 0 and vim.trim(result.stdout) or nil
  end
  me = { name = config("user.name"), mail = config("user.email") }
  return me
end

local function open_float(phantom, kind)
  local width = 0
  for _, line in ipairs(phantom.lines) do
    width = math.max(width, vim.api.nvim_strwidth(line))
  end
  width = math.max(width, vim.api.nvim_strwidth(phantom.title)) + 2

  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.api.nvim_buf_set_lines(
    buf,
    0,
    -1,
    false,
    vim.tbl_map(function(line)
      return " " .. line
    end, phantom.lines)
  )
  vim.api.nvim_buf_set_extmark(buf, vim.api.nvim_create_namespace("eldentree_phantom"), 1, 0, {
    end_row = 1,
    end_col = #phantom.lines[2] + 1,
    hl_group = "EldenPhantomSummary",
  })

  local win = vim.api.nvim_open_win(buf, false, {
    relative = "cursor",
    row = 1,
    col = 0,
    width = width,
    height = #phantom.lines,
    style = "minimal",
    border = require("core.skin").border(),
    focusable = false,
    title = { { phantom.title, KIND_GROUPS[kind] } },
    title_pos = "left",
    noautocmd = true,
  })
  vim.wo[win].winhighlight = "Normal:EldenPhantom,FloatBorder:" .. KIND_GROUPS[kind]
  vim.wo[win].winblend = 100
  return win
end

-- phantoms shimmer into the world instead of popping up
local function fade_in(state)
  state.fade = motion.tween({
    duration = 260,
    easing = "out_cubic",
    on_frame = function(t)
      if vim.api.nvim_win_is_valid(state.win) then
        vim.wo[state.win].winblend = math.floor(100 - t * 100 + 0.5)
      end
    end,
  })
end

local function summon(info, buf, dir)
  if not info or vim.api.nvim_get_current_buf() ~= buf then
    return
  end
  M.dismiss()
  local kind = actions.kind(info, identity(dir))
  local phantom = actions.describe(info, kind, os.time())
  current = { win = open_float(phantom, kind) }
  fade_in(current)
  vim.api.nvim_create_autocmd(
    { "CursorMoved", "CursorMovedI", "BufLeave", "InsertEnter", "WinScrolled" },
    {
      once = true,
      callback = M.dismiss,
    }
  )
end

--- Shows who last wrote the line under the cursor, unsaved edits included.
function M.show()
  local buf = vim.api.nvim_get_current_buf()
  local file = vim.api.nvim_buf_get_name(buf)
  if file == "" or vim.bo[buf].buftype ~= "" then
    return
  end
  local dir = vim.fs.dirname(file)
  local line = vim.api.nvim_win_get_cursor(0)[1]
  local contents = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n") .. "\n"

  -- blaming the buffer instead of the file keeps line numbers right while there are unsaved edits
  local cmd = {
    "git",
    "-C",
    dir,
    "blame",
    "--porcelain",
    "--contents",
    "-",
    "-L",
    line .. "," .. line,
    "--",
    file,
  }
  -- git translates its errors, and the untracked check reads the English one
  vim.system(
    cmd,
    { text = true, stdin = contents, env = { LC_ALL = "C" } },
    vim.schedule_wrap(function(result)
      if actions.untracked(result.stderr) then
        return summon(actions.UNWRITTEN, buf, dir)
      end
      if result.code ~= 0 then
        return vim.notify(
          "No phantoms here, this file is not in a repo",
          vim.log.levels.INFO,
          { title = "Phantom" }
        )
      end
      summon(actions.parse_porcelain(vim.split(result.stdout, "\n")), buf, dir)
    end)
  )
end

function M.setup()
  define_highlights()
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("eldentree_phantom", { clear = true }),
    callback = define_highlights,
  })
  vim.api.nvim_create_user_command("Phantom", M.show, { desc = "Show who last wrote this line" })
end

return M
