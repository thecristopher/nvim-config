local actions = require("core.claude_ui.actions")
local statusline = require("core.claude_ui.actions.statusline")
local settings = require("core.claude_ui.actions.settings")
local franchise = require("core.franchise.actions")

local elden = franchise.lore("elden_ring")
local raccoon = franchise.lore("resident_evil")
local haligtree = elden.regions[1]

-- what the statusline shows once the colors are gone
local function plain(text)
  return (text:gsub("\27%[[%d;]*m", ""))
end

local MALENIA_SESSION = {
  model = { display_name = "Opus 5.5" },
  context_window = { remaining_percentage = 62 },
  rate_limits = {
    five_hour = { used_percentage = 60 },
    seven_day = { used_percentage = 12 },
  },
}

describe("theme", function()
  it("paints Claude Code's accent with the region's gold", function()
    local theme = actions.theme(haligtree, elden.title)
    assert.equal(haligtree.palette.yellow, theme.overrides.claude)
    assert.equal("dark", theme.base)
  end)

  it("names the theme after the franchise and the region", function()
    local theme = actions.theme(haligtree, elden.title)
    assert.truthy(theme.name:find(haligtree.title, 1, true))
    assert.truthy(theme.name:find("Elden Ring", 1, true))
  end)

  it("keeps the diff backgrounds dark enough to read code on", function()
    local theme = actions.theme(haligtree, elden.title)
    assert.are_not.equal(haligtree.palette.green, theme.overrides.diffAdded)
  end)
end)

describe("hook_sound", function()
  it("rests at grace when Claude finishes", function()
    assert.equal("grace", actions.hook_sound("Stop", "fog"))
  end)

  it("dies when Claude fails", function()
    assert.equal("died", actions.hook_sound("StopFailure", "door"))
  end)

  it("puts up the franchise's own obstacle when Claude needs permission", function()
    assert.equal("fog", actions.hook_sound("PermissionRequest", "fog"))
    assert.equal("door", actions.hook_sound("PermissionRequest", "door"))
  end)

  it("stays quiet for events it does not know", function()
    assert.is_nil(actions.hook_sound("UserPromptSubmit", "fog"))
  end)
end)

describe("bar", function()
  it("fills Malenia's health to the percent left", function()
    assert.equal("██████░░░░", statusline.bar(62))
  end)

  it("clamps values outside 0 to 100", function()
    assert.equal("░░░░░", statusline.bar(-5, 5))
    assert.equal("█████", statusline.bar(140, 5))
  end)
end)

describe("render", function()
  local function ctx(lore, extra)
    return vim.tbl_extend("force", { lore = lore, region = lore.regions[1] }, extra or {})
  end

  it("shows only the model on the first row", function()
    local top = plain(statusline.render(MALENIA_SESSION, ctx(elden))[1])
    assert.equal("󰚩 Opus 5.5", top)
  end)

  it("leaves the branch, the song, the region and the runes to the editor's statusline", function()
    local extra = { branch = "feature/love-letter", song = "Inde · Shared Playlist" }
    local top = plain(statusline.render(MALENIA_SESSION, ctx(elden, extra))[1])
    assert.falsy(top:find("feature/love-letter", 1, true))
    assert.falsy(top:find("Shared Playlist", 1, true))
    assert.falsy(top:find(haligtree.title, 1, true))
    assert.falsy(top:find("◈", 1, true))
  end)

  it("draws FP and stamina in the Lands Between, with no HP bar", function()
    local bottom = plain(statusline.render(MALENIA_SESSION, ctx(elden))[2])
    assert.truthy(bottom:find("FP ████░░░░░░  40%", 1, true))
    assert.truthy(bottom:find("ST █████████░  88%", 1, true))
    assert.falsy(bottom:find("HP", 1, true))
  end)

  it("draws Claire's AMMO and HERBS without CONDITION, the ECG stays in the editor", function()
    local bottom = plain(statusline.render(MALENIA_SESSION, ctx(raccoon))[2])
    assert.falsy(bottom:find("CONDITION", 1, true))
    assert.truthy(bottom:find("AMMO", 1, true))
    assert.truthy(bottom:find("HERBS", 1, true))
  end)

  it("leaves out the bars a session does not report yet", function()
    local rows = statusline.render({ model = { display_name = "Opus 5.5" } }, ctx(elden))
    assert.equal(1, #rows)
  end)
end)

describe("merge", function()
  local plan = {
    statusline = "nvim -l statusline.lua",
    hook = "nvim -l claude/hook.lua",
    verbs = { "Seeking grace", "Combining herbs" },
    theme = "eldentree",
  }

  local function wesker_settings()
    return {
      theme = "auto",
      hooks = { Stop = { { hooks = { { type = "command", command = "cc-status" } } } } },
      spinnerVerbs = { mode = "append", verbs = { "Plotting" } },
    }
  end

  it("adds the statusline, theme, verbs and every hook", function()
    local data = wesker_settings()
    settings.merge(data, plan)
    assert.equal("nvim -l statusline.lua", data.statusLine.command)
    assert.equal("custom:eldentree", data.theme)
    assert.same({ "Plotting", "Seeking grace", "Combining herbs" }, data.spinnerVerbs.verbs)
    assert.equal(
      "nvim -l claude/hook.lua PermissionRequest",
      data.hooks.PermissionRequest[1].hooks[1].command
    )
  end)

  it("keeps the hooks that were already there", function()
    local data = wesker_settings()
    settings.merge(data, plan)
    assert.equal("cc-status", data.hooks.Stop[1].hooks[1].command)
    assert.equal("nvim -l claude/hook.lua Stop", data.hooks.Stop[2].hooks[1].command)
  end)

  it("replaces its own hooks when Malenia moves the repo", function()
    local data = wesker_settings()
    settings.merge(data, plan)
    settings.merge(
      data,
      vim.tbl_extend("force", plan, { hook = "nvim -l /haligtree/claude/hook.lua" })
    )
    assert.equal(2, #data.hooks.Stop)
    assert.equal("nvim -l /haligtree/claude/hook.lua Stop", data.hooks.Stop[2].hooks[1].command)
  end)

  it("changes nothing the second time Claire runs it", function()
    local data = wesker_settings()
    settings.merge(data, plan)
    assert.same({}, settings.merge(data, plan))
    assert.equal(2, #data.hooks.Stop)
  end)
end)

describe("verbs", function()
  it("gathers every franchise's verbs without repeats", function()
    local verbs = settings.verbs({ elden, raccoon, elden })
    assert.equal(#elden.claude.verbs + #raccoon.claude.verbs, #verbs)
    assert.equal(elden.claude.verbs[1], verbs[1])
  end)
end)
