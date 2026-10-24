local actions = require("core.snapshot.actions")

local COLORS = {
  base = "#0E0A0D", crust = "#060406", glow = "#2A1420", border = "#6E3A52",
  accent = "#E47FAD", text = "#EAD5E4", muted = "#6E5969",
}

describe("escape", function()
  it("keeps Claire's angle brackets from breaking the markup", function()
    assert.equal("a &lt; b &amp;&amp; c &gt; &quot;d&quot;", actions.escape('a < b && c > "d"'))
  end)
end)

describe("merge", function()
  it("joins neighbors with the same look", function()
    local runs = actions.merge({ { text = "lo", fg = "#FFFFFF" }, { text = "ve", fg = "#FFFFFF" } })
    assert.same({ { text = "love", fg = "#FFFFFF" } }, runs)
  end)

  it("splits where the color changes", function()
    assert.equal(2, #actions.merge({ { text = "a", fg = "#111111" }, { text = "b", fg = "#222222" } }))
  end)

  it("splits where only the weight changes", function()
    assert.equal(2, #actions.merge({ { text = "a", fg = "#111111" }, { text = "b", fg = "#111111", bold = true } }))
  end)
end)

describe("common_indent", function()
  it("finds the indent every line of Malenia's snippet shares", function()
    assert.equal(4, actions.common_indent({ "    if bloom then", "      rot()", "    end" }))
  end)

  it("ignores blank lines when measuring", function()
    assert.equal(2, actions.common_indent({ "  a", "", "    b" }))
  end)

  it("is zero for code already flush left", function()
    assert.equal(0, actions.common_indent({ "local inde = true" }))
  end)
end)

describe("svg", function()
  local rows = { { { text = "local ", fg = "#E47FAD", bold = true }, { text = "date = \"anniversary\"", fg = "#9DB87A" } } }
  local svg = actions.svg(rows, { title = "love.lua", region = "ELDENTREE  ·  HALIGTREE", first_line = 12, colors = COLORS })

  it("is a standalone svg document", function()
    assert.is_truthy(svg:match("^<svg "))
    assert.is_truthy(svg:match("</svg>$"))
  end)

  it("paints each run with its own color and weight", function()
    assert.is_truthy(svg:find('<tspan fill="#E47FAD" font-weight="bold">local </tspan>', 1, true))
  end)

  it("escapes the code it carries", function()
    assert.is_truthy(svg:find("&quot;anniversary&quot;", 1, true))
  end)

  it("numbers the lines from where the selection started", function()
    assert.is_truthy(svg:find(">12  </tspan>", 1, true))
  end)

  it("frames the card with the file name and the region", function()
    assert.is_truthy(svg:find("love.lua", 1, true))
    assert.is_truthy(svg:find("HALIGTREE", 1, true))
  end)
end)

describe("size", function()
  it("never makes a card narrower than a readable minimum", function()
    assert.is_true(actions.size({ { { text = "x" } } }, 0).card_width >= 520)
  end)

  it("grows with every line", function()
    local one = actions.size({ {} }, 0)
    local two = actions.size({ {}, {} }, 0)
    assert.equal(actions.LINE, two.card_height - one.card_height)
  end)
end)
