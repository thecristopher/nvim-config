-- Settings for recording the README demos with vhs: quiet, the same world on every take, and only
-- the made up repos scripts/record.sh builds. Loaded with `nvim --cmd "luafile $DEMO_LUA"`.
vim.g.eldentree_sound = false
vim.g.eldentree_franchise = vim.env.DEMO_FRANCHISE or "elden_ring"
vim.g.eldentree_region = vim.env.DEMO_REGION
vim.g.eldentree_title = vim.env.DEMO_TITLE == "1"
vim.g.eldentree_music = vim.env.DEMO_MUSIC == "1"
vim.g.eldentree_repo_roots = { vim.env.DEMO_ROOTS }

-- DEMO_SEED=1 fills the take's fresh state with a made up year: the chronicle, the bestiary, most
-- feats and a song, so the feats tape unlocks the last two on screen and the year card has a year
if vim.env.DEMO_SEED == "1" then
  local state = vim.fn.stdpath("state")
  vim.fn.mkdir(state, "p")
  local function write(name, value)
    vim.fn.writefile({ vim.json.encode(value) }, state .. "/" .. name)
  end
  local ranks = { "S", "A", "A", "B", "S", "C", "A" }
  local chronicle = {}
  local first = os.time({ year = 2026, month = 2, day = 14, hour = 12 })
  for day = 0, 119 do
    local date = os.date("%Y-%m-%d", first + day * 86400)
    chronicle[date] = {
      seconds = 3 * 3600 + day * 60,
      saves = 40 + day % 9,
      fixes = 12 + day % 7,
      rank = ranks[day % 7 + 1],
    }
  end
  write("eldentree_chronicle.json", chronicle)
  write("eldentree_bestiary.json", {
    [vim.env.DEMO_REPO or "/haligtree"] = {
      ["Lua undefined-global"] = { kills = 412, last = "2026-06-10" },
      ["Lua unused-local"] = { kills = 230, last = "2026-06-11" },
      ["ts 2322"] = { kills = 388, last = "2026-06-12" },
    },
  })
  write("eldentree_feats.json", {
    first_blood = "2026-02-14",
    hundred_foes = "2026-02-20",
    thousand_foes = "2026-05-30",
    first_s = "2026-02-14",
    ten_s = "2026-04-02",
    week_streak = "2026-02-21",
    marathon = "2026-03-08",
  })
  write("eldentree_music.json", {
    ["2026"] = { ["the cure|lovesong"] = { title = "Lovesong", artist = "The Cure", plays = 64 } },
  })
end
