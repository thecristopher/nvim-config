# Chrome

`lua/core/chrome/`: the editor's chrome per franchise. The mode badge says the franchise's mode
names (`chrome.modes` in the lore) and fades into the next mode's color, line numbers fade with
their distance to the cursor (the statuscolumn wraps snacks' one), windows out of focus drop their
cursor line and dim every number to the faintest step (`number_group(relnum, focused)`), so the eye
finds the active window at once (trees, pickers and lists keep their cursor line, it is their
selection), the statusline's language piece is the filetype icon plus the attached servers
(`language_label`) and terminals are named by their shell (`terminal_title`), with no toggleterm
extension so the bar stays the same everywhere, every statusline piece has a minimum editor width in
`STATUSLINE_MIN` (music leaves first, the language last) so a narrow screen drops pieces instead of
lualine cutting the bar with `<`, scratch screens like the HUD show neither a file name nor a
language (`names_itself`), bufferline tabs are sized to their names (`tab_size = 12`) and a new file
opens beside the current one, the neo-tree root shows the project's name instead of its path and the
tree drops the "(1 hidden item)" row, there is no colorcolumn: `core/chrome/ruler.lua` tints only
the part of a line past `textwidth` (or 100) with `EldenOverLength`, so inline blame and long
comments are never split, and wrapped prose without a textwidth goes without (`ruler_applies`),
closed folds carry their hidden line tally as a quiet italic note (`UfoFoldedEllipsis`) instead of
catppuccin's bright pill, notifications are titled with the franchise's word for their level and the
hour (`chrome.notify`), and `<leader>uN` opens Eldentree's own notification history
(`core/chrome/notify.lua` `show_history`, lines from `history_lines`) titled `chrome.history`
between the skin's ornaments with the same level words, since snacks keeps its history style
private, pickers take the layout the skin names (`picker`: `grace`, `inventory` or `vanity`) with
titles between the ornaments and the preview called `chrome.examine`, and the noice command line is
titled `chrome.cmdline` / `chrome.search` with the skin's `cmdline` glyphs, renamed in place on
every switch. Words live in the lore's `chrome`, shapes in the skin, `:checkhealth` checks both.
Statusline tiers in `STATUSLINE_MIN`: everything from 170 columns, from 120 the bar keeps mode,
branch, path, diagnostics, language and position (CI and threads from 130, the diff from 140, the
status piece from 150), below 120 only mode, path, diagnostics and position. The path is fitted by
`fit_path` within `path_budget` and the branch cut by `short_branch`, so lualine never cuts with
`<`.
