local actions = require("core.claude.actions")

local function never() return false end
local function only(path) return function(p) return p == path end end

describe("fallback_paths", function()
  it("looks for claude.exe in Leon's .local/bin on Windows", function()
    local paths = actions.fallback_paths("C:/Users/leon", "C:/Users/leon/AppData/Roaming", true)
    assert.equals("C:/Users/leon/.local/bin/claude.exe", paths[1])
  end)

  it("includes the npm shim on Windows", function()
    local paths = actions.fallback_paths("C:/Users/leon", "C:/Users/leon/AppData/Roaming", true)
    assert.is_true(vim.tbl_contains(paths, "C:/Users/leon/AppData/Roaming/npm/claude.cmd"))
  end)

  it("uses bare names everywhere else", function()
    local paths = actions.fallback_paths("/home/jill", "", false)
    assert.equals("/home/jill/.local/bin/claude", paths[1])
  end)
end)

describe("resolve", function()
  it("prefers the override Wesker pinned", function()
    assert.equals("D:/umbrella/claude.exe", actions.resolve("D:/umbrella/claude.exe", "C:/bin/claude.exe", {}, never))
  end)

  it("uses PATH when there is no override", function()
    assert.equals("C:/bin/claude.exe", actions.resolve(nil, "C:/bin/claude.exe", {}, never))
  end)

  it("falls back to the first executable install when PATH is broken", function()
    local fallbacks = { "C:/a/claude.exe", "C:/b/claude.cmd" }
    assert.equals("C:/b/claude.cmd", actions.resolve(nil, "", fallbacks, only("C:/b/claude.cmd")))
  end)

  it("returns nil when claude is nowhere to be found", function()
    assert.is_nil(actions.resolve("", "", { "C:/a/claude.exe" }, never))
  end)
end)

describe("command", function()
  it("keeps the prompt out of argv so cmd.exe never sees it", function()
    assert.same({ "claude", "-p", "--disallowedTools", actions.DISALLOWED_TOOLS }, actions.command("claude"))
  end)
end)
