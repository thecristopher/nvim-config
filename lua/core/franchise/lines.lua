-- The plain lines every franchise can say in its own words: the HUD's labels and greetings, and
-- what the commit, PR, review and trial helpers say while they work. A lore's lines.lua fills the
-- same keys, a key it leaves out falls back to these, and :checkhealth asks every lore for all of
-- them. A line may be a list, one is picked each time. Holes: {character} is the region's
-- character, {traveler} what the world calls you, {world} the franchise, plus the ones a line
-- names itself.
return {
  -- the HUD
  ["hud.inventory"] = "Inventory",
  ["hud.quest"] = "Current Quest",
  ["hud.empty"] = "Nothing here yet",
  ["hud.no_sites"] = "No project found yet",
  ["hud.no_quest"] = "No quest here, p travels to one of your {sites}",
  ["hud.greeting_night"] = "The night is long, {traveler}",
  ["hud.greeting_morning"] = "Good morning, {traveler}",
  ["hud.greeting_afternoon"] = "Good afternoon, {traveler}",
  ["hud.greeting_evening"] = "Good evening, {traveler}",
  ["hud.hint_use"] = "Use",
  ["hud.hint_command"] = "Command",
  ["hud.hint_check"] = "Check",
  ["hud.hint_combine"] = "Combine",
  ["hud.hint_tabs"] = "Tabs",
  ["hud.hint_move"] = "Move",
  ["hud.hint_quest"] = "Quest",
  ["hud.hint_session"] = "Session",
  ["hud.hint_quit"] = "Quit",
  ["hud.resume"] = "Pick up where you left off: {file}.",
  ["hud.restore"] = "Restore Session",
  ["hud.restore_desc"] = "Bring back the last visit here.",
  ["hud.back"] = "Back to work",
  ["hud.back_desc"] = "Close the inventory and start an empty buffer.",
  ["hud.leave"] = "Leave {world}",
  ["hud.leave_desc"] = "Close nvim.",
  ["hud.switch_desc"] = "Wake up in {target} for the rest of the day.",

  -- drafting a commit with Claude
  ["commit.title"] = "Commit",
  ["commit.drafting"] = "Drafting commit message with Claude…",
  ["commit.ready"] = "Draft ready",
  ["commit.failed"] = "Claude could not draft the commit",
  ["commit.window"] = "Commit Message",
  ["commit.done"] = "Committed: {subject}",
  ["commit.nothing"] = "Nothing to commit.",
  ["commit.left_out"] = "Left out of the commit: {files}",
  ["commit.fell"] = "git commit failed",

  -- drafting and opening a pull request with Claude
  ["pr.title"] = "PR Helper",
  ["pr.commits"] = "Reading the commits…",
  ["pr.diff"] = "Reading the diff…",
  ["pr.github"] = "Asking GitHub for an open PR…",
  ["pr.context"] = "Diff context ready",
  ["pr.drafting"] = "Drafting PR description with Claude…",
  ["pr.ready"] = "Draft ready",
  ["pr.failed"] = "Claude could not draft the PR",
  ["pr.pushing"] = "Pushing '{branch}' to origin…",
  ["pr.talking"] = "Talking to GitHub…",
  ["pr.creating"] = "Creating PR on GitHub…",
  ["pr.updating"] = "Updating PR #{number} on GitHub…",
  ["pr.created"] = "Created PR: {url}",
  ["pr.updated"] = "Updated PR #{number}: {url}",
  ["pr.lost"] = "the pull request did not survive",
  ["pr.window_create"] = "Create PR",
  ["pr.window_update"] = "Update PR #{number}",

  -- Claude reviewing a pull request
  ["review.title"] = "Review",
  ["review.looking"] = "Looking for open PRs…",
  ["review.fetching"] = "Fetching PR #{number}…",
  ["review.diff"] = "Fetching the diff of PR #{number}…",
  ["review.reading"] = "Claude is reading PR #{number}…",
  ["review.done"] = "PR #{number} analyzed",

  -- running the test suite
  ["trial.title"] = "Trial",
  ["trial.facing"] = "Facing the trial: {command}",
  ["trial.passed"] = "All tests passed",
  ["trial.won"] = "all tests passed",
  ["trial.lost"] = "the tests have spoken",
}
