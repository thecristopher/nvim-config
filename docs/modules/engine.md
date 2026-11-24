# Engine

`lua/eldentree/init.lua`: `require("eldentree").setup(opts)` sets up every core module in the order
they need each other (`ORDER` in `lua/eldentree/modules.lua`). This config calls it from `init.lua`
with `vim.g.eldentree_modules`, so `options_local.lua` can turn whole modules off:

```lua
vim.g.eldentree_modules = { skip = { "music", "desk" } }
```

`only` keeps just the modules named, `skip` leaves some out, and `franchise`, `skin` and `motion`
always run because every other module reads them (`REQUIRED`). An unknown name is reported, and a
module that fails to set up is reported with its traceback while the rest still run.

## In another config

The repo works as a plugin: nothing runs on its own (there is no `plugin/` folder and its `init.lua`
is only read when it is the config). Its one hard dependency is snacks.nvim, the pickers, images and
notifications of 16 modules go through `Snacks`. With lazy.nvim:

```lua
{
  "thecristopher/nvim-config",
  name = "eldentree",
  lazy = false,
  priority = 900,
  dependencies = { "folke/snacks.nvim" },
  config = function()
    require("eldentree").setup({ only = { "banner", "boss", "bestiary", "results", "chronicle", "feats", "wrapped", "season" } })
  end,
}
```

Sounds, portraits, lore and the spell list are found from `require("core.utils").root()`, the folder
the engine lives in, so they work the same from the config or from lazy's plugin folder. The look of
the other plugins (lualine, bufferline, neo-tree, blink) lives in this config's `lua/plugins/`, so a
borrowed engine brings the worlds, the games and the screens, and its statusline pieces only show
where the other config adds them to its own lualine.

Two things to know before borrowing it: its modules live under `core.*` and `eldentree.*`, so a
config with its own `lua/core/` shadows or is shadowed by them, and `leader` binds the leader keys
in `lua/core/leader/actions/init.lua`, so leave it out with `skip` to keep your own.

`tests/core/eldentree_modules_spec.lua` checks every module in `ORDER` has a `setup` and every core
module with one is either in `ORDER` or set up on purpose elsewhere (init.lua or a plugin spec).
