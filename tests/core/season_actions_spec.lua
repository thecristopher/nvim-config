local season = require("core.season.actions")

describe("season", function()
  it("brings Halloween to Claire's last week of October", function()
    assert.equal("halloween", season.season({ month = 10, day = 31 }).name)
  end)

  it("snows over Malenia's December", function()
    assert.equal("winter", season.season({ month = 12, day = 24 }).name)
  end)

  it("keeps an ordinary day ordinary", function()
    assert.is_nil(season.season({ month = 11, day = 23 }))
  end)

  it("lets Inde's anniversary win over any holiday", function()
    assert.equal("anniversary", season.season({ month = 10, day = 28 }, "10-28").name)
  end)

  it("ignores an anniversary written the wrong way", function()
    assert.is_nil(season.parse_anniversary("Feb 14"))
    assert.same({ 2, 14 }, season.parse_anniversary("02-14"))
  end)
end)

describe("franchise", function()
  it("brings Resident Evil on Halloween when it plays here", function()
    local halloween = season.season({ month = 10, day = 25 })
    assert.equal("resident_evil", season.franchise(halloween, { "elden_ring", "resident_evil" }))
  end)

  it("leaves the day's pick alone when the season's franchise does not play here", function()
    local anniversary = season.season({ month = 2, day = 14 }, "02-14")
    assert.is_nil(season.franchise(anniversary, { "elden_ring", "resident_evil" }))
  end)

  it("brings no franchise in winter", function()
    assert.is_nil(season.franchise(season.season({ month = 12, day = 20 }), { "elden_ring" }))
  end)
end)

describe("weather", function()
  it("paints every season's weather with palette slots", function()
    for _, entry in ipairs(season.SEASONS) do
      assert.is_string(entry.weather.from)
      assert.is_string(entry.weather.to)
      assert.equal(2, #entry.weather.speed)
    end
  end)
end)

describe("named", function()
  it("finds Halloween for Claire's preview", function()
    assert.equal("Halloween", season.named("halloween").title)
  end)

  it("finds nothing for a season Wesker made up", function()
    assert.is_nil(season.named("umbrella_summer"))
  end)

  it("names every season for completion", function()
    assert.same({ "anniversary", "halloween", "winter", "new_year" }, season.names())
  end)
end)
