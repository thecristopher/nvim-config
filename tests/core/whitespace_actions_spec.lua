local actions = require("core.whitespace.actions")

describe("changed_ranges", function()
  it("keeps the lines Claire added to the love letter", function()
    assert.same({ { 3, 5 } }, actions.changed_ranges({ { 2, 1, 3, 3 } }))
  end)

  it("skips hunks that only deleted lines", function()
    assert.same({}, actions.changed_ranges({ { 4, 2, 3, 0 } }))
  end)

  it("returns every changed block in order", function()
    assert.same({ { 1, 1 }, { 9, 10 } }, actions.changed_ranges({ { 1, 1, 1, 1 }, { 8, 0, 9, 2 } }))
  end)
end)

describe("trim", function()
  it("drops the spaces Malenia left after her promise to Inde", function()
    assert.equal("i will wait for you", actions.trim("i will wait for you   \t"))
  end)

  it("leaves leading indentation alone", function()
    assert.equal("    return anniversary", actions.trim("    return anniversary  "))
  end)
end)

describe("strip_carriage_returns", function()
  it("cleans the lines readfile leaves on a dos playlist", function()
    assert.same({ "claire", "inde" }, actions.strip_carriage_returns({ "claire\r", "inde" }))
  end)
end)
