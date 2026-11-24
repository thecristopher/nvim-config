local actions = require("core.curtain.actions")

describe("cover", function()
  it("starts with the stage in plain sight", function()
    assert.equal(0, actions.cover(0))
  end)

  it("keeps the drapes closed while the next stage is announced", function()
    assert.equal(1, actions.cover((actions.CLOSE_UNTIL + actions.OPEN_FROM) / 2))
  end)

  it("parts them completely once Claire walks on", function()
    assert.near(0, actions.cover(1), 0.0001)
  end)
end)

describe("drape_width", function()
  it("covers nothing while the curtain is open", function()
    assert.equal(0, actions.drape_width(120, 0))
  end)

  it("meets in the middle of an even screen", function()
    assert.equal(60, actions.drape_width(120, 1))
  end)

  it("leaves no gap in the middle of an odd screen", function()
    assert.equal(61, actions.drape_width(121, 1))
  end)
end)

describe("runs", function()
  local function total(runs)
    local columns = 0
    for _, run in ipairs(runs) do
      columns = columns + run[1]
    end
    return columns
  end

  it("spans exactly the drape's width", function()
    assert.equal(37, total(actions.runs(37, "left")))
  end)

  it("folds the left drape from its inner edge on the right", function()
    local runs = actions.runs(6, "left")
    assert.equal(actions.shade_at(0), runs[#runs][2])
  end)

  it("folds the right drape from its inner edge on the left", function()
    local runs = actions.runs(6, "right")
    assert.equal(actions.shade_at(0), runs[1][2])
  end)

  it("draws an empty drape as no velvet at all", function()
    assert.same({}, actions.runs(0, "left"))
  end)
end)

describe("shade_at", function()
  it("repeats the fold so Inde sees the velvet ripple", function()
    assert.equal(actions.shade_at(1), actions.shade_at(1 + #actions.FOLD))
  end)
end)

describe("sign window", function()
  it("starts once the drapes have met", function()
    assert.equal(actions.CLOSE_UNTIL, actions.SIGN.from)
    assert.equal(1, actions.cover(actions.SIGN.from))
  end)

  it("sets the stage while the drapes are closed", function()
    assert.equal(1, actions.cover(actions.COVERED))
  end)

  it("is gone before Malenia's stage is fully open", function()
    assert.is_true(actions.cover(actions.SIGN.to) > 0)
  end)
end)
