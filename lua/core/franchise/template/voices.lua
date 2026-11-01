-- What the character of each region says when something happens, one table per region name.
-- Write a voice sheet in docs/voices/ first, then the lines from it. {branch} and {boss} are
-- filled in when the moment has them.
return {
  first_region = {
    trial_passed = { "Every test passed." },
    trial_failed = { "The tests failed." },
    ci_passed = { "{branch} passed CI." },
    ci_failed = { "{branch} failed CI." },
    pushed = { "{branch} is pushed." },
    boss_felled = { "{boss} is down." },
  },
}
