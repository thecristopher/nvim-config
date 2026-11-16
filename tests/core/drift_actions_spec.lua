local actions = require("core.drift.actions")

local function calm(overrides)
  return vim.tbl_extend("force", {
    enabled = true,
    buftype = "",
    filetype = "markdown",
    empty = false,
    diff = false,
    floating = false,
    mode = "n",
    resting = false,
  }, overrides or {})
end

describe("should_drift", function()
  it("lets the weather fall under Claire's love letter while she reads it", function()
    assert.is_true(actions.should_drift(calm()))
  end)

  it("keeps the sky still while Malenia writes", function()
    assert.is_false(actions.should_drift(calm({ mode = "i" })))
    assert.is_false(actions.should_drift(calm({ mode = "v" })))
  end)

  it("stays out of terminals, diffs, floats and the rest", function()
    assert.is_false(actions.should_drift(calm({ buftype = "terminal" })))
    assert.is_false(actions.should_drift(calm({ diff = true })))
    assert.is_false(actions.should_drift(calm({ floating = true })))
    assert.is_false(actions.should_drift(calm({ resting = true })))
  end)

  it("keeps Malenia's code calm, weather is for prose and blank pages", function()
    assert.is_false(actions.should_drift(calm({ filetype = "lua" })))
    assert.is_true(actions.should_drift(calm({ filetype = "gitcommit" })))
    assert.is_true(actions.should_drift(calm({ filetype = "", empty = true })))
  end)

  it("goes quiet when Inde turns it off", function()
    assert.is_false(actions.should_drift(calm({ enabled = false })))
  end)
end)

describe("sky", function()
  it("opens under the last line of Inde's playlist", function()
    assert.same({ row = 12, height = 28 }, actions.sky(12, 40))
  end)

  it("leaves a margin of two rows alone", function()
    assert.is_nil(actions.sky(38, 40))
  end)
end)

describe("placement", function()
  local info = { winrow = 2, wincol = 31, width = 100, textoff = 6, winbar = 1 }

  it("covers only the text columns under Claire's file, past its winbar", function()
    assert.same(
      { row = 1 + 1 + 10, col = 30 + 6, width = 94, height = 5 },
      actions.placement(info, { row = 10, height = 5 })
    )
  end)

  it("gives up when the gutter takes the whole window", function()
    assert.is_nil(
      actions.placement(vim.tbl_extend("force", info, { width = 6 }), { row = 0, height = 4 })
    )
  end)
end)

describe("budget", function()
  it("draws half the HUD's weather and never fewer than two flakes", function()
    assert.equal(10, actions.budget(20))
    assert.equal(2, actions.budget(1))
  end)
end)

describe("same_place", function()
  it("knows Malenia's sky did not move", function()
    local a = { row = 1, col = 2, width = 3, height = 4 }
    assert.is_true(actions.same_place(a, vim.deepcopy(a)))
    assert.is_false(actions.same_place(a, vim.tbl_extend("force", a, { height = 5 })))
    assert.is_false(actions.same_place(a, nil))
    assert.is_true(actions.same_place(nil, nil))
  end)
end)
