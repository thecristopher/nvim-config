local glint = require("core.chrome.actions.glint")

describe("section_of", function()
  it("finds the badge Claire saved from in normal mode", function()
    assert.equal("a", glint.section_of("lualine_a_normal", "normal"))
  end)

  it("mirrors the right side onto the left, so z glows with a", function()
    assert.equal("a", glint.section_of("lualine_z_location_normal", "normal"))
    assert.equal("b", glint.section_of("lualine_y_runes_normal", "normal"))
    assert.equal("c", glint.section_of("lualine_x_diagnostics_error_normal", "normal"))
  end)

  it("leaves Malenia's insert groups alone while she saves in normal mode", function()
    assert.is_nil(glint.section_of("lualine_a_insert", "normal"))
  end)

  it("ignores groups that are not lualine sections", function()
    assert.is_nil(glint.section_of("EldenMusicLine", "normal"))
  end)
end)

describe("transitional_sections", function()
  it("reads both sides of the separator between Inde's badge and branch", function()
    local left, right = glint.transitional_sections(
      "lualine_transitional_lualine_a_normal_to_lualine_b_normal",
      "normal"
    )
    assert.equal("a", left)
    assert.equal("b", right)
  end)

  it("skips a separator of another mode", function()
    assert.is_nil(
      glint.transitional_sections(
        "lualine_transitional_lualine_a_visual_to_lualine_b_visual",
        "normal"
      )
    )
  end)
end)

describe("strength", function()
  it("stays dark before the badge's turn", function()
    assert.equal(0, glint.strength(0, "a"))
  end)

  it("peaks halfway through each section's span", function()
    local peak = glint.START_MS + glint.SPAN_MS / 2
    assert.is_true(math.abs(glint.strength(peak, "a") - 1) < 1e-9)
  end)

  it("lights the middle after the badge, so the glint runs toward Claire's cursor", function()
    local early = glint.START_MS + 40
    assert.is_true(glint.strength(early, "a") > 0)
    assert.equal(0, glint.strength(early, "c"))
  end)

  it("is dark again everywhere once the glint is over", function()
    for _, section in ipairs({ "a", "b", "c" }) do
      assert.equal(0, glint.strength(glint.TOTAL_MS, section))
    end
  end)
end)

describe("glinted", function()
  it("rests exactly on the theme's color when the glint is out", function()
    assert.equal("#1E1E2E", glint.glinted("#1E1E2E", "#D8B45A", 0))
  end)

  it("rests on Claire's theme color when no light is given, the way the glint ends", function()
    assert.equal("#1E1E2E", glint.glinted("#1E1E2E", nil, 0))
  end)

  it("warms Malenia's branch toward the gold at the peak", function()
    local lit = glint.glinted("#000000", "#FFFFFF", 1)
    assert.are_not.equal("#000000", lit)
  end)
end)

describe("lights", function()
  it("brightens the badge to the text and the rest to the accent", function()
    local lights = glint.lights({ text = "#CDD6F4", yellow = "#D8B45A" })
    assert.equal("#CDD6F4", lights.a)
    assert.equal("#D8B45A", lights.c)
  end)
end)
