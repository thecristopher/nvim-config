-- The takes each region's character performs out loud through Fish Audio (core/voice/studio), two
-- per moment, written with Drama 3 direction: [how it is said] before the words, <emphasis>,
-- <whisper>, <soft> and <slow> around the words they shape, [break] for a pause. `voice` is the Fish
-- Audio voice id the region is cast with, a region without one stays written. Moments are the ones
-- in core/voice/actions MOMENTS and SPOKEN.
return {
  first_region = {
    -- voice = "<Fish Audio voice id>",
    takes = {
      trial_passed = {
        "[relieved] Every test passed.",
        "[proud, warm] All green. I knew you had it.",
      },
    },
  },
}
