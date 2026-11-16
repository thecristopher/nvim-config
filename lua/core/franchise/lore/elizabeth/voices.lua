-- What Elizabeth says in each role when something happens, written from the voice sheet in
-- docs/voices/elizabeth.md. {branch} and {boss} are filled in when the moment has them.
return {
  westview = {
    trial_passed = {
      "Every test green. I didn't even have to rewrite reality this time.",
      "All passing. See? Some things are exactly what they seem.",
      "Clean run. Come sit with me, the sun is still on the window.",
      "Green across the board. I knew it, I always know.",
    },
    trial_failed = {
      "Red. It's fine, nothing here is permanent. Not even this.",
      "A test broke. We don't hex it away, we fix it. Together.",
      "Breathe. I've held worse together than one failing suite.",
      "That one hurts a little. Show me where, I'm right here.",
    },
    ci_passed = {
      "CI cleared {branch}. The whole town is cheering for you.",
      "{branch} passed. No magic, just you. I like that better.",
      "All clear on {branch}. Dinner is my spell tonight.",
    },
    ci_failed = {
      "{branch} failed CI. Reality wobbles, and then we steady it.",
      "The pipeline broke {branch}. The pipeline, not you.",
      "Red on {branch}. Give me your hand, we go back in.",
    },
    pushed = {
      "{branch} is out there now. Let it fly.",
      "Pushed {branch}. Quiet, confident. Very you.",
      "{branch} left the house. I'll keep the porch light on.",
    },
    boss_felled = {
      "{boss} is gone. Nobody touches what's ours.",
      "{boss} broke first. I told you it would.",
      "That was {boss}. You barely needed me. Barely.",
    },
  },
  separate_ways = {
    trial_passed = {
      "All green. Don't look so surprised, I wasn't.",
      "Clean. You're getting good at this. Dangerous.",
      "Every test passed. I'll let you buy me a drink.",
      "Green. I'd say I'm impressed, but you already know.",
    },
    trial_failed = {
      "Red. Happens to the best of us. Rarely to me.",
      "A failing test. Funny, I thought you had this one.",
      "Try again. I'll be watching from somewhere you can't see.",
      "Don't sulk. Reload and take the shot properly.",
    },
    ci_passed = {
      "{branch} made it through. Quietly. My kind of job.",
      "CI cleared {branch}. No witnesses, no trouble.",
      "{branch} passed. I'll take the credit, you take the coffee.",
    },
    ci_failed = {
      "{branch} didn't make it. Pick another way in.",
      "CI caught {branch}. Sloppy. Not like you.",
      "{branch} failed. I've had worse nights. You'll fix it by morning.",
    },
    pushed = {
      "{branch} is out. Now walk away like you meant it.",
      "Pushed {branch}. Clean exit. I approve.",
      "{branch} is gone. Nobody saw a thing.",
    },
    boss_felled = {
      "{boss} is down. You owe me nothing. This time.",
      "{boss} never saw us coming.",
      "That's {boss} handled. Try to keep up, partner.",
    },
  },
  moonrise_towers = {
    trial_passed = {
      "Every test passed. Selûne is smiling, and so, I suppose, am I.",
      "All green. I'd pray in thanks, but you did the work.",
      "Clean. You almost make this look easy. Almost.",
      "The tests hold. Good. I was not looking forward to healing them.",
    },
    trial_failed = {
      "Red again. Fine. I've patched up worse than this.",
      "A failed test. Sit still, let me look at the wound.",
      "Don't give me that face. We fix it, then we rest.",
      "The tests failed. Shar would love this. Let's disappoint her.",
    },
    ci_passed = {
      "CI blessed {branch}. Moonlight suits it.",
      "{branch} passed. I'll admit it, I'm proud of you.",
      "All clear on {branch}. Come, the night is ours.",
    },
    ci_failed = {
      "{branch} fell in CI. Up you get, I'm not carrying you.",
      "CI cursed {branch}. Curses break. I would know.",
      "{branch} failed. Hand me the logs, and stay close.",
    },
    pushed = {
      "{branch} is on its way. May the moon light its path.",
      "Pushed {branch}. Bold. I like bold.",
      "{branch} is gone. No turning back now, and I don't want to.",
    },
    boss_felled = {
      "{boss} is down. And we're still standing. Together.",
      "That was {boss}. The dark lost again.",
      "{boss} is finished. Let's find a quiet spot under the moon.",
    },
  },
  danger_room = {
    trial_passed = {
      "All green. Focus is a blade, and you just drew it.",
      "Every test passed. I felt that one land from across the room.",
      "Clean run. Now come here, the sun is still warm on the floor.",
      "Green. No wasted motion. That's how I like it.",
    },
    trial_failed = {
      "Red. The blade slipped, it happens. Breathe and draw again.",
      "A test failed. I can read it already, it's a small one.",
      "Don't flinch. We reset the room and run it again.",
      "That one fought back. Good, now we know where it hides.",
    },
    ci_passed = {
      "{branch} cleared CI. Sharp and quiet, like a good strike.",
      "CI passed {branch}. I knew before it finished. I always do.",
      "{branch} is green. Training's over, you're taking me out.",
    },
    ci_failed = {
      "{branch} failed CI. The simulation cheated, not you.",
      "Red on {branch}. Show me the logs, I'll find the flaw.",
      "{branch} went down in CI. Up, the room is resetting.",
    },
    pushed = {
      "{branch} is out. One clean cut, no hesitation.",
      "Pushed {branch}. I like the way you commit to things.",
      "{branch} is gone. Let the next round come.",
    },
    boss_felled = {
      "{boss} is down. That's what a focused mind does.",
      "{boss} never stood a chance against the two of us.",
      "That was {boss}. Sheathe it, we earned the evening.",
    },
  },
}
