-- What the character of each location says when something happens, written from the voice sheets
-- in docs/voices/resident_evil.md. {branch} and {boss} are filled in when the moment has them.
return {
  raccoon_city = {
    trial_passed = {
      "All green. Told you we'd make it out of this one together.",
      "Clean run. Save me the seat behind you on the bike tonight.",
      "Every test standing. I knew you had it in you, partner.",
      "That's how you walk out of Raccoon City. I'm proud of you.",
    },
    trial_failed = {
      "Red again? Okay. Breathe, I'm right here. Let's look at it.",
      "Ugh, seriously? Come on, we've survived way worse than this.",
      "That test picked the wrong couple to mess with. Back in we go.",
      "Grab a green herb, partner. Then we fix it, together.",
    },
    ci_passed = {
      "CI cleared {branch}. Dinner's on me tonight.",
      "{branch} made it out clean. You never stop surprising me.",
      "All clear on {branch}. Now come here and take a break with me.",
    },
    ci_failed = {
      "CI went down on {branch}. I'm not leaving you alone with this one.",
      "Mayday on {branch}. Eyes on me, we fix it and we get out.",
      "{branch} didn't make it. Hey, it's the pipeline, not you.",
    },
    pushed = {
      "{branch} is out the door. Keep the engine running for me.",
      "Pushed {branch}. Look at you, not even breaking a sweat.",
      "{branch} is on its way. Ride's not over yet, partner.",
    },
    boss_felled = {
      "{boss} is down. You okay? Good. Stay close.",
      "We got {boss}. Remind me to never let you out of my sight.",
      "{boss} won't bother us again. Nobody gets left behind, not you.",
    },
  },
  rpd = {
    trial_passed = {
      "All green. Guess the tests finally learned some manners.",
      "Clean sweep. Hunnigan's gonna think I made that up.",
      "Every test's standing. Not bad for a rookie's first night.",
    },
    trial_failed = {
      "Red. Figures. Anyone else want to take a shot at us?",
      "Tests went south. I've had worse days. Most of them, actually.",
      "Failing again? I'll add it to the list, right after the chainsaw guy.",
    },
    ci_passed = {
      "{branch} is clear. Mission accomplished, more or less.",
      "CI signed off on {branch}. Somebody tell Hunnigan.",
      "{branch} made it through. Didn't even need the parry.",
    },
    ci_failed = {
      "CI took {branch} down. Of course it did.",
      "{branch} failed. Okay. Knife out, let's go.",
      "Lost {branch} on CI. Nothing a little overtime can't fix.",
    },
    pushed = {
      "{branch} is out. Escort complete.",
      "Pushed {branch}. Nobody shot at it. Yet.",
      "{branch} is on the road. I'll cover the rear.",
    },
    boss_felled = {
      "{boss} is down. Next time, knock.",
      "So much for {boss}. Should've stayed in bed.",
      "{boss}'s done. That one's going in the report.",
    },
  },
  spencer_mansion = {
    trial_passed = {
      "All tests clear. Area secured.",
      "Green across the board. Moving on.",
      "Lock picked, every test through. Next door.",
    },
    trial_failed = {
      "Tests failed. Noted. Finding the weak point.",
      "Not clean. Regroup, check the logs, go again.",
      "Red. Umbrella would love that. We fix it first.",
    },
    ci_passed = {
      "{branch} cleared CI. Confirmed.",
      "CI reports {branch} green. S.T.A.R.S. standards met.",
      "{branch} is secure. Logging it.",
    },
    ci_failed = {
      "CI down on {branch}. Assessing the damage.",
      "{branch} failed. I find the fault, then we move.",
      "{branch} hit a trap. Disarm it, retry.",
    },
    pushed = {
      "{branch} pushed. Perimeter holds.",
      "{branch} delivered. On to the next objective.",
      "Push confirmed on {branch}.",
    },
    boss_felled = {
      "{boss} neutralized. Stay alert, there's always another.",
      "{boss} is down. Don't count on it staying that way.",
      "Target {boss} eliminated. Moving out.",
    },
  },
  umbrella_lab = {
    trial_passed = {
      "Every test passes. As I predicted.",
      "Adequate. You are evolving, slowly.",
      "All green. Even you can follow a superior design.",
    },
    trial_failed = {
      "The tests failed. I expected nothing less from you.",
      "Failure. How very human of you.",
      "Red. The weak always reveal themselves. Correct it.",
    },
    ci_passed = {
      "{branch} passed. A small step toward a new world.",
      "CI approves {branch}. Its approval was never in question.",
      "{branch} survives selection. Interesting.",
    },
    ci_failed = {
      "{branch} did not survive CI. Natural selection is merciless.",
      "CI rejected {branch}. I had already accounted for that.",
      "{branch} failed. Do not waste my time with excuses.",
    },
    pushed = {
      "{branch} is released. Let us see what adapts.",
      "You pushed {branch}. Everything proceeds according to my plan.",
      "{branch} is out in the world. The world is not ready.",
    },
    boss_felled = {
      "{boss} has fallen. It was never a worthy specimen.",
      "{boss} is eliminated. Do not mistake that for strength.",
      "{boss} served its purpose. Discard it.",
    },
  },
  the_island = {
    trial_passed = {
      "All green. I'd say I'm impressed, but I knew you would.",
      "Clean run. Don't let it go to your head.",
      "Every test passed. Right on schedule.",
    },
    trial_failed = {
      "Red. Lucky for you, I always have a plan B.",
      "Failing tests. Cute. Try again.",
      "Didn't go as planned? Plans rarely do.",
    },
    ci_passed = {
      "{branch} cleared CI. My employer will be pleased.",
      "{branch} is clean. You're full of surprises.",
      "CI let {branch} through. Smooth.",
    },
    ci_failed = {
      "{branch} failed CI. I'd fix that before anyone notices.",
      "CI caught {branch}. Sloppy. Not like you.",
      "{branch} is down. I'll pretend I didn't see that.",
    },
    pushed = {
      "{branch} is out. I was never here.",
      "Pushed {branch}. Now disappear before anyone asks questions.",
      "{branch} is on its way. See you around.",
    },
    boss_felled = {
      "{boss} is done. I keep the sample, you keep the credit.",
      "So {boss} falls. Saved me the trouble.",
      "{boss} is down. Until next time.",
    },
  },
}
