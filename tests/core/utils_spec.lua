local utils = require("core.utils")

describe("hash", function()
  it("gives the same number for the same love letter every time", function()
    assert.equal(utils.hash("claire loves inde"), utils.hash("claire loves inde"))
  end)

  it("tells two different notes apart", function()
    assert.are_not.equal(utils.hash("malenia"), utils.hash("melina"))
  end)

  it("starts from the djb2 seed for empty text", function()
    assert.equal(5381, utils.hash(""))
  end)

  it("stays within 32 bits for long text", function()
    assert.is_true(utils.hash(("radahn"):rep(500)) < 4294967296)
  end)
end)
