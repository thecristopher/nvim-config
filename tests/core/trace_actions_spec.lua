local trace = require("core.trace.actions")

describe("remember", function()
  it("forgets Claire's oldest keystroke once the memory is full", function()
    local memory = trace.remember(trace.remember(trace.remember({}, "C"), "l"), "a", 2)
    assert.same({ "l", "a" }, memory)
  end)
end)

describe("describe_key", function()
  it("keeps a plain key as typed", function()
    assert.equal("s", trace.describe_key("s", "s"))
  end)

  it("shows what a mapping turned Inde's keys into", function()
    assert.equal("k><Esc>", trace.describe_key("<Esc>", "k"))
  end)

  it("marks keys nobody typed", function()
    assert.equal("{<Esc>}", trace.describe_key("<Esc>", ""))
  end)
end)

describe("left_insert", function()
  it("catches insert falling back to normal", function()
    assert.is_true(trace.left_insert("i", "n"))
    assert.is_true(trace.left_insert("ic", "niI"))
  end)

  it("ignores Malenia entering insert", function()
    assert.is_false(trace.left_insert("n", "i"))
  end)
end)

describe("suspect", function()
  it("blames the person when they pressed Esc", function()
    assert.equal("you pressed Esc", trace.suspect({ "a", "<Esc>" }))
  end)

  it("blames a mapping that produced Esc", function()
    assert.equal("a mapping turned k into Esc", trace.suspect({ "j", "k><Esc>" }))
  end)

  it("blames a plugin that sent Esc on its own", function()
    assert.equal("a plugin sent Esc (s came before it)", trace.suspect({ "s", "{<Esc>}" }))
  end)

  it("says no Esc arrived when something else ended insert", function()
    assert.equal("no Esc arrived, something switched windows or called stopinsert", trace.suspect({ "s", "a" }))
  end)
end)

describe("entry", function()
  it("writes one readable line for the love letter file", function()
    local line = trace.entry("21:52:09", { "s", "a" }, { file = "letters/inde.md", filetype = "markdown", floats = 1, mode = "n" })
    assert.is_truthy(line:find("letters/inde.md markdown, 1 floats", 1, true))
    assert.is_truthy(line:find("keys: s a", 1, true))
  end)
end)
