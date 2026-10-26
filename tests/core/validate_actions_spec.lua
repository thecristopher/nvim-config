local validate = require("core.franchise.actions.validate")

local function lore()
  return vim.deepcopy(require("core.franchise.actions").lore("resident_evil"))
end

local function mentions(problems, text)
  for _, problem in ipairs(problems) do
    if problem:find(text, 1, true) then
      return true
    end
  end
  return false
end

describe("problems", function()
  it("finds nothing wrong with Resident Evil", function()
    assert.same({}, validate.problems(lore()))
  end)

  it("notices a region without a boss", function()
    local broken = lore()
    broken.bosses.raccoon_city = nil
    assert.is_true(mentions(validate.problems(broken), "raccoon_city has no boss"))
  end)

  it("notices a missing word", function()
    local broken = lore()
    broken.words.traveler = nil
    assert.is_true(mentions(validate.problems(broken), "words.traveler"))
  end)

  it("asks for typewriter words only when the franchise rests at one", function()
    local elden = vim.deepcopy(require("core.franchise.actions").lore("elden_ring"))
    assert.is_false(mentions(validate.problems(elden), "words.typewriter"))
    local broken = lore()
    broken.words.typewriter = nil
    assert.is_true(mentions(validate.problems(broken), "words.typewriter"))
  end)

  it("notices the music panel missing the words Claire sings to Inde", function()
    local broken = lore()
    broken.music.missing = nil
    assert.is_true(mentions(validate.problems(broken), "music.missing"))
  end)

  it("notices the music panel missing its progress bar", function()
    local broken = lore()
    broken.skin.music.bar = nil
    assert.is_true(mentions(validate.problems(broken), "skin.music.bar"))
  end)

  it("notices a palette slot that is not a color", function()
    local broken = lore()
    broken.regions[1].palette.text = "white"
    assert.is_true(mentions(validate.problems(broken), "palette.text"))
  end)

  it("notices Claire and Jill sharing an accent", function()
    local broken = lore()
    broken.regions[2].palette.yellow = broken.regions[1].palette.yellow
    assert.is_true(mentions(validate.problems(broken), "shares its accent"))
  end)

  it("notices a portrait that is not on disk", function()
    local function nothing_on_disk()
      return false
    end
    assert.is_true(
      mentions(validate.problems(lore(), nothing_on_disk), "is not in images/portraits")
    )
  end)

  it("notices a missing skin piece", function()
    local broken = lore()
    broken.skin = vim.deepcopy(broken.skin)
    broken.skin.border = nil
    assert.is_true(mentions(validate.problems(broken), "skin.border"))
  end)
end)
