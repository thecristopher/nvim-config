#!/usr/bin/env bash
# Measures how long the real config takes to draw its first frame and to finish VeryLazy, inside a
# pseudo terminal so the UI events fire like they do for a person. Prints the median of RUNS runs.
#   ./scripts/startup.sh [runs] [file]
set -euo pipefail

runs="${1:-10}"
file="${2:-}"
out="$(mktemp -d)"
trap 'rm -rf "$out"' EXIT

cat >"$out/probe.lua" <<LUA
local t0 = vim.uv.hrtime()
local marks = {}
vim.api.nvim_create_autocmd("UIEnter", { once = true, callback = function()
  marks.ui = (vim.uv.hrtime() - t0) / 1e6
end })
vim.api.nvim_create_autocmd("User", { pattern = "VeryLazy", once = true, callback = function()
  -- scheduled, so it counts every VeryLazy handler, not just the moment the event fired
  vim.schedule(function()
  marks.lazy = (vim.uv.hrtime() - t0) / 1e6
  vim.fn.writefile({ string.format("%.1f %.1f", marks.ui or 0, marks.lazy) }, "$out/run.txt", "a")
  -- quitting while the start screen still animates its entrance gets swallowed, so it waits it out
  vim.defer_fn(function()
    vim.cmd("qall!")
  end, 1500)
  end)
end })
LUA

for _ in $(seq "$runs"); do
  # script gives nvim a terminal, the flags differ between BSD (macOS) and util-linux
  if [ "$(uname)" = "Darwin" ]; then
    script -q /dev/null nvim --cmd "luafile $out/probe.lua" $file >/dev/null 2>&1 </dev/null
  else
    script -qec "nvim --cmd 'luafile $out/probe.lua' $file" /dev/null >/dev/null 2>&1 </dev/null
  fi
done

median() { sort -n | awk '{ v[NR] = $1 } END { print v[int((NR + 1) / 2)] }'; }
echo "first frame (UIEnter):  $(cut -d' ' -f1 "$out/run.txt" | median) ms"
echo "ready (VeryLazy done): $(cut -d' ' -f2 "$out/run.txt" | median) ms"
echo "median of $(wc -l <"$out/run.txt" | tr -d ' ') runs"
