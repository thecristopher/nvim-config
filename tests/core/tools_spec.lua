local tools = require("eldentree.tools")

describe("TOOLS", function()
  it("has every Homebrew formula in the Brewfile Claire installs from", function()
    local brewfile = table.concat(vim.fn.readfile("Brewfile"), "\n")
    for _, tool in ipairs(tools.TOOLS) do
      if tool.brew then
        assert.is_truthy(brewfile:find('brew "' .. tool.brew .. '"', 1, true), tool.brew)
      end
    end
  end)

  it("says where every tool comes from", function()
    for _, tool in ipairs(tools.TOOLS) do
      assert.is_truthy(tool.brew or tool.from, tools.name(tool))
    end
  end)
end)

describe("present", function()
  it("accepts any executable that stands in for Malenia's portrait tool", function()
    local magick = { bin = { "magick", "convert" }, gives = "portraits" }
    assert.is_true(tools.present(magick, function(bin)
      return bin == "convert"
    end))
  end)

  it("misses a tool Inde has not installed", function()
    assert.is_false(tools.present({ bin = "lazygit", gives = "" }, function()
      return false
    end))
  end)
end)

describe("for_platform", function()
  it("leaves the mac only tools out of Leon's Linux box", function()
    local list = { { bin = "git" }, { bin = "swiftc", os = "mac" } }
    assert.same({ { bin = "git" } }, tools.for_platform(list, false))
  end)
end)

describe("how_to_install", function()
  it("names the formula when Homebrew has one", function()
    assert.equal("`brew install gh`", tools.how_to_install({ bin = "gh", brew = "gh" }))
  end)

  it("points elsewhere when it does not", function()
    assert.equal(
      "xcode-select --install",
      tools.how_to_install({ bin = "swiftc", from = "xcode-select --install" })
    )
  end)
end)
