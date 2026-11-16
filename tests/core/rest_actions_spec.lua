local actions = require("core.rest.actions")

local function idle(overrides)
  return vim.tbl_extend(
    "force",
    { idle = actions.DEFAULT_AFTER_MS, mode = "n", enabled = true, resting = false },
    overrides or {}
  )
end

describe("should_rest", function()
  it("rests after a long idle in normal mode", function()
    assert.is_true(actions.should_rest(idle()))
  end)

  it("stays awake while Melina is still typing in insert mode", function()
    assert.is_false(actions.should_rest(idle({ mode = "i" })))
  end)

  it("stays awake before the threshold", function()
    assert.is_false(actions.should_rest(idle({ idle = 1000 })))
  end)

  it("honors a custom threshold", function()
    assert.is_true(actions.should_rest(idle({ idle = 2000, after = 1000 })))
  end)

  it("never rests twice at once", function()
    assert.is_false(actions.should_rest(idle({ resting = true })))
  end)

  it("never rests when motion is off", function()
    assert.is_false(actions.should_rest(idle({ enabled = false })))
  end)
end)

describe("veil_alpha", function()
  it("starts clear", function()
    assert.equal(0, actions.veil_alpha(0))
  end)

  it("settles at its deepest once the fade ends", function()
    assert.near(actions.DEEPEST_ALPHA, actions.veil_alpha(actions.FADE_MS * 2), 0.0001)
  end)
end)

describe("text_alpha", function()
  it("waits for the dark before the words appear", function()
    assert.equal(0, actions.text_alpha(actions.FADE_MS * 0.4))
  end)
end)

describe("layout", function()
  it("centers every line", function()
    for _, line in ipairs(actions.layout(120, 40, "Raya Lucaria")) do
      local width = vim.fn.strdisplaywidth(line.text)
      assert.is_true(math.abs((line.col + width / 2) - 60) <= 1, line.text)
    end
  end)

  it("names the region you are resting in", function()
    local texts = vim.tbl_map(function(line)
      return line.text
    end, actions.layout(120, 40, "Caelid"))
    assert.is_true(vim.tbl_contains(texts, "Caelid"))
  end)
end)

describe("typed", function()
  it("has written nothing before the veil settles", function()
    assert.equal("", (actions.typed("Will you use an Ink Ribbon?", 0)))
  end)

  it("writes one letter per keystroke", function()
    local written = actions.typed("Jill", actions.FADE_MS * 0.5 + actions.TYPE_MS * 2)
    assert.equal("Ji", written)
  end)

  it("finishes the line and says so", function()
    local written, done = actions.typed("Jill", 60000)
    assert.equal("Jill", written)
    assert.is_true(done)
  end)
end)

describe("layout in a safe room", function()
  before_each(function()
    vim.g.eldentree_franchise = "resident_evil"
  end)
  after_each(function()
    vim.g.eldentree_franchise = "elden_ring"
  end)

  it("asks Jill about the ink ribbon on a typed line", function()
    local lines = actions.layout(100, 40, "Spencer Mansion", { style = "typewriter", ribbons = 3 })
    local typed = vim.tbl_filter(function(line)
      return line.typed
    end, lines)
    assert.equal("Will you use an Ink Ribbon?", typed[1].text)
  end)

  it("counts the ribbons used this run", function()
    local lines = actions.layout(100, 40, "Spencer Mansion", { style = "typewriter", ribbons = 3 })
    assert.is_truthy(vim.tbl_contains(
      vim.tbl_map(function(line)
        return line.text
      end, lines),
      "Ink Ribbons ×3"
    ))
  end)
end)

describe("golden hour", function()
  it("rests under the heart in the afternoon sun", function()
    local layout = actions.layout(120, 40, "Westview", { style = "golden_hour" })
    assert.equal("󰋑", layout[1].text)
  end)
end)

describe("sun_spans", function()
  it("never lets the sun spill past the screen", function()
    for _, span in ipairs(actions.sun_spans(80, 24, 6000)) do
      assert.is_true(span.from >= 0 and span.to <= 80 and span.from < span.to)
    end
  end)

  it("keeps every blind in the shade while Claire naps", function()
    for _, span in ipairs(actions.sun_spans(120, 40, 0)) do
      assert.are_not.equal(actions.SUN.slat - 1, span.row % actions.SUN.slat)
    end
  end)

  it("leans the light like a low sun", function()
    local spans = actions.sun_spans(200, 40, 0)
    assert.is_true(spans[#spans].from > spans[1].from)
  end)

  it("sways as the afternoon goes by", function()
    local before = actions.sun_spans(200, 40, 0)[1].from
    local later = actions.sun_spans(200, 40, actions.SUN.sway_ms / 4)[1].from
    assert.are_not.equal(before, later)
  end)
end)
