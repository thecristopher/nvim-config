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

  it("notices Claire with nothing to say when a push lands", function()
    local broken = lore()
    broken.voices.raccoon_city.pushed = nil
    assert.is_true(mentions(validate.problems(broken), "raccoon_city has no voice for pushed"))
  end)

  it("notices a franchise with no name for the drills", function()
    local broken = lore()
    broken.coach.training = nil
    assert.is_true(mentions(validate.problems(broken), "coach.training"))
  end)

  it("notices a franchise with no words for the CI run", function()
    local broken = lore()
    broken.ci.failed = nil
    assert.is_true(mentions(validate.problems(broken), "ci.failed"))
  end)

  it("notices a bestiary with no enemies for Leon to fight", function()
    local broken = lore()
    broken.bestiary.enemies = {}
    assert.is_true(mentions(validate.problems(broken), "bestiary.enemies is empty"))
  end)

  it("notices a coach that cannot sell Claire a hint", function()
    local broken = lore()
    broken.coach.hint = nil
    assert.is_true(mentions(validate.problems(broken), "coach.hint"))
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

  it("notices Claire traveling by a mechanic nobody built", function()
    local broken = lore()
    broken.mechanics.travel = "helicopter"
    assert.is_true(mentions(validate.problems(broken), "mechanics.travel is helicopter"))
  end)

  it("accepts every travel, status and rest Elizabeth plays", function()
    local dressed = lore()
    dressed.mechanics.travel = "curtain"
    dressed.mechanics.status = "heartbeat"
    dressed.mechanics.rest = "golden_hour"
    assert.same({}, validate.problems(dressed))
  end)

  it("notices a HUD view that does not exist", function()
    local broken = lore()
    broken.skin.dashboard = "love_letters"
    assert.is_true(mentions(validate.problems(broken), "skin.dashboard is love_letters"))
  end)

  it("notices a title style the title screen cannot draw", function()
    local broken = lore()
    broken.skin.title.style = "confetti"
    assert.is_true(mentions(validate.problems(broken), "skin.title.style is confetti"))
  end)

  it("notices a figure that is not on disk", function()
    local broken = lore()
    broken.regions[1].figure = "claire_whole.jpg"
    local function only_portraits(file)
      return file ~= "claire_whole.jpg"
    end
    assert.is_true(mentions(validate.problems(broken, only_portraits), "figure claire_whole.jpg"))
  end)

  it("accepts a villain who steals the scene", function()
    local dressed = lore()
    dressed.mechanics.boss = "scene"
    assert.same({}, validate.problems(dressed))
  end)

  it("notices a border nvim-ufo would refuse while Claire travels", function()
    local broken = lore()
    broken.skin.border = "bold"
    assert.is_true(mentions(validate.problems(broken), "skin.border is bold"))
  end)

  it("notices a missing skin piece", function()
    local broken = lore()
    broken.skin = vim.deepcopy(broken.skin)
    broken.skin.border = nil
    assert.is_true(mentions(validate.problems(broken), "skin.border"))
  end)
end)
