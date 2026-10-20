local actions = require("core.style.actions")

describe("strip_frontmatter", function()
  it("drops the frontmatter from Claire's guide", function()
    local guide = "---\ndescription: claire's rules\n---\n\n# Love letters to Inde"
    assert.equals("# Love letters to Inde", actions.strip_frontmatter(guide))
  end)

  it("leaves Malenia's guide alone when it has no frontmatter", function()
    assert.equals("# Rot, but make it tidy", actions.strip_frontmatter("# Rot, but make it tidy\n"))
  end)
end)

describe("prompt_lines", function()
  it("falls back to plain rules when Inde has no guide yet", function()
    assert.same(actions.FALLBACK, actions.prompt_lines(nil))
  end)

  it("treats a blank guide as missing", function()
    assert.same(actions.FALLBACK, actions.prompt_lines("  \n"))
  end)

  it("puts Claire's guide body last so claude reads it whole", function()
    local lines = actions.prompt_lines("---\nname: x\n---\nAlways date Malenia on Fridays")
    assert.equals("Always date Malenia on Fridays", lines[#lines])
  end)
end)
