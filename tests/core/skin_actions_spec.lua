local actions = require("core.skin.actions")

describe("toggleterm_border", function()
  it("calls rounded curved, the way toggleterm does", function()
    assert.equal("curved", actions.toggleterm_border("rounded"))
  end)

  it("passes double through untouched", function()
    assert.equal("double", actions.toggleterm_border("double"))
  end)
end)

describe("ornate", function()
  it("frames Malenia's title in gold ornaments", function()
    assert.equal("◈ Malenia ◈", actions.ornate("Malenia", { ornament = { "◈ ", " ◈" } }))
  end)

  it("leaves the title bare when the skin has no ornament", function()
    assert.equal("Claire", actions.ornate("Claire", {}))
  end)
end)

describe("sign_text", function()
  it("keys every sign by its severity", function()
    local severity = vim.diagnostic.severity
    local text =
      actions.sign_text({ error = "󰂧", warn = "▲", hint = "◆", info = "◇" }, severity)
    assert.equal("󰂧", text[severity.ERROR])
    assert.equal("◇", text[severity.INFO])
  end)
end)

describe("level_icon", function()
  local icons = { error = "󰋔", info = "󰆥" }

  it("dresses Inde's error in the franchise's glyph", function()
    assert.equal("󰋔", actions.level_icon(icons, "error", nil))
  end)

  it("keeps the glyph Claire's notification already brought", function()
    assert.equal("󰗶", actions.level_icon(icons, "error", "󰗶"))
  end)

  it("treats a blank glyph as none, the way snacks leaves it", function()
    assert.equal("󰆥", actions.level_icon(icons, "info", ""))
  end)

  it("stays empty for a level the skin has no glyph for", function()
    assert.equal("", actions.level_icon(icons, "trace", nil))
    assert.equal("", actions.level_icon(nil, "warn", nil))
  end)
end)

describe("glyph options", function()
  local glyphs = {
    list = { tab = "▸ ", trail = "░", nbsp = "␣" },
    fold = { open = "󰋑", close = "󰋕" },
    diff = "╱",
    keys = { breadcrumb = "▶", separator = "▸", group = "▪ " },
  }

  it("marks Jill's trailing spaces with static", function()
    assert.same({ tab = "▸ ", trail = "░", nbsp = "␣" }, actions.listchars(glyphs))
  end)

  it("folds Inde's love letters under hearts and keeps the filler blank", function()
    local fill = actions.fillchars(glyphs)
    assert.equal("󰋑", fill.foldopen)
    assert.equal("󰋕", fill.foldclose)
    assert.equal(" ", fill.eob)
  end)

  it("draws the lines between Claire's windows and past her letter's end in the skin", function()
    local fill = actions.fillchars(vim.tbl_extend("force", glyphs, {
      eob = "·",
      split = { vert = "║", horiz = "═" },
    }))
    assert.equal("·", fill.eob)
    assert.equal("║", fill.vert)
    assert.equal("═", fill.horiz)
  end)

  it("hands which-key only the three marks it draws", function()
    assert.same(
      { breadcrumb = "▶", separator = "▸", group = "▪ " },
      actions.which_key_icons(glyphs)
    )
  end)
end)

describe("forget_resolved_opts", function()
  it("lets Claire's bufferline read the new franchise's tabs on the next setup", function()
    local plugin = { _ = { cache = { opts = { separator_style = "thick" }, keys = { "x" } } } }
    actions.forget_resolved_opts(plugin)
    assert.is_nil(plugin._.cache.opts)
    assert.same({ "x" }, plugin._.cache.keys)
  end)

  it("leaves a plugin lazy never resolved alone", function()
    assert.has_no.errors(function()
      actions.forget_resolved_opts({ _ = {} })
      actions.forget_resolved_opts(nil)
    end)
  end)
end)
