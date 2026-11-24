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

  it("puts the model beside the region's character under the franchise's mark", function()
    local top = plain(statusline.render(MALENIA_SESSION, ctx(elden))[1])
    assert.equal("󰚩 Opus 5.5  ◈ " .. elden.regions[1].character, top)
  end)

  it("names Inde's branch only when Claude runs outside nvim", function()
    local outside =
      plain(statusline.render(MALENIA_SESSION, ctx(elden, { branch = "feature/love-letter" }))[1])
    assert.truthy(outside:find("󰘬 feature/love-letter", 1, true))
    local inside = plain(statusline.render(MALENIA_SESSION, ctx(elden))[1])
    assert.falsy(inside:find("󰘬", 1, true))
  end)

  it("leaves the song, the region and the runes to the editor's statusline", function()
    local extra = { song = "Inde · Shared Playlist" }
    local top = plain(statusline.render(MALENIA_SESSION, ctx(elden, extra))[1])
    assert.falsy(top:find("Shared Playlist", 1, true))
    assert.falsy(top:find(haligtree.title, 1, true))
  end)

  it("says what Claire's session has cost and how long it ran", function()
    local session = vim.tbl_extend("force", MALENIA_SESSION, {
      cost = { total_cost_usd = 1.5, total_duration_ms = 75 * 60000 },
    })
    local bottom = plain(statusline.render(session, ctx(raccoon))[2])
    assert.truthy(bottom:find("$1.50", 1, true))
    assert.truthy(bottom:find("󰔛 1h 15m", 1, true))
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

  it("draws Wanda's own HEX and CHAOS instead of the stage's bars", function()
    local wardrobe = franchise.lore("elizabeth")
    local bottom = plain(statusline.render(MALENIA_SESSION, ctx(wardrobe))[2])
    assert.truthy(bottom:find("HEX", 1, true))
    assert.truthy(bottom:find("CHAOS", 1, true))
    assert.falsy(bottom:find(wardrobe.claude.bars.five_hour, 1, true))
  end)

  it("leaves out the bars a session does not report yet", function()
    local rows = statusline.render({ model = { display_name = "Opus 5.5" } }, ctx(elden))
    assert.equal(1, #rows)
  end)
end)

describe("duration", function()
  it("counts Malenia's short session in minutes", function()
    assert.equal("12m", statusline.duration(12 * 60000))
  end)

  it("stays quiet when the session did not say", function()
    assert.is_nil(statusline.duration(nil))
  end)
end)

describe("branch", function()
  it("reads Claire's branch out of HEAD", function()
    assert.equal("feature/anniversary", statusline.branch("ref: refs/heads/feature/anniversary"))
  end)

  it("gives nil for a detached head", function()
    assert.is_nil(statusline.branch("4f2a9c1"))
  end)
end)

describe("should_play", function()
  local now = 1000

  it("calls Inde back when a long turn ends", function()
    assert.is_true(actions.should_play("Stop", { now = now, turn_started = now - 60 }))
  end)

  it("stays quiet when a short turn ends while Claire is still watching", function()
    assert.is_false(actions.should_play("Stop", { now = now, turn_started = now - 5 }))
  end)

  it("still rings when nobody knows when the turn began", function()
    assert.is_true(actions.should_play("Stop", { now = now }))
  end)

  it("rings a burst of permission prompts once", function()
    assert.is_false(
      actions.should_play("PermissionRequest", { now = now, last_permission = now - 4 })
    )
    assert.is_true(
      actions.should_play("PermissionRequest", { now = now, last_permission = now - 90 })
    )
  end)

  it("keeps Malenia's expedition silent", function()
    local ctx = { now = now, turn_started = now - 300, expedition_until = now + 600 }
    assert.is_false(actions.should_play("Stop", ctx))
    assert.is_false(actions.should_play("StopFailure", ctx))
  end)
end)

describe("background", function()
  it("knows the desk's listener by the start of its session id", function()
    assert.is_true(actions.background("84ef2984-aaaa-bbbb", { "", "84ef2984" }))
  end)

  it("lets Claire's own sessions ring", function()
    assert.is_false(actions.background("c1a1e000-aaaa", { "84ef2984" }))
    assert.is_false(actions.background(nil, { "84ef2984" }))
    assert.is_false(actions.background("c1a1e000-aaaa", { "" }))
  end)
end)

describe("session_file", function()
  it("keeps only safe characters of Claire's session id", function()
    assert.equal("abc-123", actions.session_file("abc-123/../"))
    assert.equal("default", actions.session_file(nil))
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

describe("verbs_for", function()
  local wardrobe = franchise.lore("elizabeth")
  local function role(name)
    return vim.iter(wardrobe.regions):find(function(region)
      return region.name == name
    end)
  end

  it("spins Wanda's verbs and the stage's, never Psylocke's", function()
    local verbs = settings.verbs_for(wardrobe, role("westview"))
    assert.truthy(vim.tbl_contains(verbs, "Weaving a hex"))
    assert.truthy(vim.tbl_contains(verbs, wardrobe.claude.verbs[1]))
    assert.falsy(vim.tbl_contains(verbs, "Focusing the psychic blade"))
  end)

  it("falls back to the franchise's verbs for a region without its own", function()
    assert.same(elden.claude.verbs, settings.verbs_for(elden, haligtree))
  end)
end)

describe("set_verbs", function()
  local known = { "Weaving a hex", "Focusing the psychic blade", "Rehearsing the scene" }

  it("swaps Wanda's verbs for Psylocke's and keeps Claire's own", function()
    local data = {
      spinnerVerbs = { mode = "append", verbs = { "Plotting", "Weaving a hex" } },
    }
    assert.is_true(settings.set_verbs(data, { "Focusing the psychic blade" }, known))
    assert.same({ "Plotting", "Focusing the psychic blade" }, data.spinnerVerbs.verbs)
  end)

  it("says nothing changed when Malenia keeps her role", function()
    local data = { spinnerVerbs = { mode = "append", verbs = { "Rehearsing the scene" } } }
    assert.is_false(settings.set_verbs(data, { "Rehearsing the scene" }, known))
  end)
end)

describe("known_verbs", function()
  it("gathers every franchise's and every role's verbs without repeats", function()
    local wardrobe = franchise.lore("elizabeth")
    local verbs = settings.known_verbs({ elden, raccoon, wardrobe, elden })
    assert.truthy(vim.tbl_contains(verbs, elden.claude.verbs[1]))
    assert.truthy(vim.tbl_contains(verbs, "Waiting on the bloom"))
    assert.equal(#verbs, #vim.tbl_keys(vim.iter(verbs):fold({}, function(seen, verb)
      seen[verb] = true
      return seen
    end)))
  end)
end)
