local utils = require("core.utils")

describe("hash", function()
  it("gives the same number for the same love letter every time", function()
    assert.equal(utils.hash("claire loves inde"), utils.hash("claire loves inde"))
  end)

  it("tells two different notes apart", function()
    assert.are_not.equal(utils.hash("malenia"), utils.hash("melina"))
  end)

  it("starts from the djb2 seed for empty text", function()
    assert.equal(5381, utils.hash(""))
  end)

  it("stays within 32 bits for long text", function()
    assert.is_true(utils.hash(("radahn"):rep(500)) < 4294967296)
  end)
end)

describe("executable_perm", function()
  it("lets everyone who can read Inde's script run it", function()
    assert.equal("rwxr-xr-x", utils.executable_perm("rw-r--r--"))
  end)

  it("keeps Wesker's private file private", function()
    assert.equal("rwx------", utils.executable_perm("rw-------"))
  end)

  it("leaves a script that already runs as it is", function()
    assert.equal("rwxr-xr-x", utils.executable_perm("rwxr-xr-x"))
  end)
end)

describe("platform", function()
  it("names the OS Malenia is running nvim on", function()
    assert.is_true(vim.tbl_contains({ "mac", "windows", "linux" }, utils.platform()))
  end)
end)

describe("write_state", function()
  local path

  before_each(function()
    path = vim.fn.tempname()
  end)

  after_each(function()
    os.remove(path)
  end)

  it("keeps Claire's note to Inde on disk", function()
    assert.is_true(utils.write_state(path, { "see you at the lighthouse" }))
    assert.same({ "see you at the lighthouse" }, vim.fn.readfile(path))
  end)

  it("appends Malenia's next line when asked to", function()
    utils.write_state(path, { "first date" })
    utils.write_state(path, { "anniversary" }, "a")
    assert.same({ "first date", "anniversary" }, vim.fn.readfile(path))
  end)

  it("reports a write it could not make", function()
    assert.is_false(utils.write_state("/nonexistent/haligtree/note", { "lost" }))
  end)
end)
