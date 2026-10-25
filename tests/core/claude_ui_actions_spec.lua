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

describe("condition", function()
  it("reads Claire as fine with most of the context left", function()
    assert.equal("fine", statusline.condition(80))
  end)

  it("turns to caution and then danger as the context runs out", function()
    assert.equal("caution", statusline.condition(40))
    assert.equal("danger", statusline.condition(10))
  end)
end)

describe("thousands", function()
  it("groups Inde's runes by thousands", function()
    assert.equal("161,150", statusline.thousands(161150))
    assert.equal("999", statusline.thousands(999))
    assert.equal("1,000,000", statusline.thousands(1000000))
  end)
end)

describe("render", function()
  local function ctx(lore, extra)
    return vim.tbl_extend("force", {
      lore = lore,
      region = lore.regions[1],
      ecg = lore.mechanics.status == "ecg",
      now_ms = 0,
    }, extra or {})
  end

  it("shows the region, branch, model, runes and song on the first row", function()
    local rows = statusline.render(
      MALENIA_SESSION,
      ctx(
        elden,
        { branch = "feature/love-letter", runes = 161150, song = "󰎈 Inde · Shared Playlist" }
      )
    )
    local top = plain(rows[1])
    assert.truthy(top:find(haligtree.title, 1, true))
    assert.truthy(top:find("feature/love-letter", 1, true))
    assert.truthy(top:find("Opus 5.5", 1, true))
    assert.truthy(top:find("◈ 161,150", 1, true))
    assert.truthy(top:find("Inde · Shared Playlist", 1, true))
  end)

  it("draws HP, FP and stamina in the Lands Between", function()
    local bottom = plain(statusline.render(MALENIA_SESSION, ctx(elden))[2])
    assert.truthy(bottom:find("HP ██████░░░░  62%", 1, true))
    assert.truthy(bottom:find("FP ████░░░░░░  40%", 1, true))
    assert.truthy(bottom:find("ST █████████░  88%", 1, true))
  end)

  it("puts Claire's CONDITION monitor in Raccoon City", function()
    local bottom = plain(statusline.render(MALENIA_SESSION, ctx(raccoon))[2])
    assert.truthy(bottom:find("CONDITION", 1, true))
    assert.truthy(bottom:find("Fine", 1, true))
    assert.truthy(bottom:find("AMMO", 1, true))
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
