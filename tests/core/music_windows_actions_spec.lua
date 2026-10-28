local windows = require("core.music.actions.windows")

-- reads back the script powershell would run from its -EncodedCommand argument
local function script_of(cmd)
  return vim.iconv(vim.base64.decode(cmd[#cmd]), "utf-16le", "utf-8")
end

describe("powershell", function()
  it("runs Windows PowerShell with the script encoded", function()
    local cmd = windows.status_command()
    assert.equal("powershell.exe", cmd[1])
    assert.equal("-EncodedCommand", cmd[#cmd - 1])
  end)

  it("looks for Apple Music among the media sessions", function()
    local script = script_of(windows.status_command())
    assert.truthy(script:find("-match '" .. windows.APPS .. "'", 1, true))
    assert.truthy(script:find("GlobalSystemMediaTransportControlsSessionManager", 1, true))
  end)
end)

describe("status_command", function()
  it("answers in the tab separated shape parse_music reads", function()
    local script = script_of(windows.status_command())
    assert.truthy(script:find('$media.AlbumTitle) -join "`t"', 1, true))
  end)
end)

describe("control_command", function()
  it("skips Claire's song with the media session", function()
    assert.truthy(script_of(windows.control_command("next")):find("TrySkipNextAsync", 1, true))
  end)

  it("toggles play and pause for Inde's playlist", function()
    local script = script_of(windows.control_command("playpause"))
    assert.truthy(script:find("TryTogglePlayPauseAsync", 1, true))
  end)

  it("gives nil for a control the players do not know", function()
    assert.is_nil(windows.control_command("rewind"))
  end)
end)

describe("cover_command", function()
  it("writes the cover where it is told, with single quotes doubled", function()
    local script = script_of(windows.cover_command("C:\\Users\\Malenia\\Inde's mixtape.part"))
    assert.truthy(script:find("Create('C:\\Users\\Malenia\\Inde''s mixtape.part')", 1, true))
  end)
end)
