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
  zebes = {
    trial_passed = {
      "All green. Scan complete, no threats left.",
      "Every test passed. Mission logged.",
      "Clean run. Suit off, sun's still up. Stay a while.",
      "Green. I don't say much. I'm proud of you.",
    },
    trial_failed = {
      "Red. Scan the failure, find the weak point.",
      "A test failed. I've lost my whole suit before. We recover.",
      "Hold position. We go back in with better gear.",
      "That one hit hard. Get up, I'm right behind you.",
    },
    ci_passed = {
      "{branch} cleared CI. Target neutralized.",
      "CI passed {branch}. Quiet work, clean result.",
      "{branch} is green. Mission over, dinner's on the ship.",
    },
    ci_failed = {
      "{branch} failed CI. The pipeline's a hostile planet, not your fault.",
      "Red on {branch}. Check the logs, we find another path.",
      "{branch} went down. Recharge and drop back in.",
    },
    pushed = {
      "{branch} launched. Clean liftoff.",
      "Pushed {branch}. Next sector.",
      "{branch} is in orbit. I'll watch it from here.",
    },
    boss_felled = {
      "{boss} is down. Again. They never learn.",
      "{boss} is gone. Good shooting, partner.",
      "That was {boss}. The planet's quiet now. Just us.",
    },
  },
  limbo = {
    trial_passed = {
      "All green. Even Limbo couldn't find anything wrong.",
      "Every test passed. Don't look so surprised, it was always yours.",
      "Clean run. Put the sword down, sit with me.",
      "Green. Good. I hate cleaning up demons.",
    },
    trial_failed = {
      "Red. Something crawled out of Limbo. We send it back.",
      "A test failed. I've walked out of worse places than this.",
      "Breathe. I'll open a disc, we try again from the top.",
      "That one bites. Show me, the sword cuts through it.",
    },
    ci_passed = {
      "{branch} cleared CI. Not a single demon in sight.",
      "CI passed {branch}. I teleported in just to watch.",
      "{branch} is green. You earned a quiet night.",
    },
    ci_failed = {
      "{branch} failed CI. The pipeline is cursed, you aren't.",
      "Red on {branch}. I've seen this demon before, it dies fast.",
      "{branch} fell in CI. Up. We step through and fix it.",
    },
    pushed = {
      "{branch} is through the disc. Gone.",
      "Pushed {branch}. Clean cut, no looking back.",
      "{branch} left Limbo. Let it go.",
    },
    boss_felled = {
      "{boss} is banished. This realm is mine, and you're in it.",
      "{boss} never stood a chance against the soulsword.",
      "That was {boss}. Limbo is quiet. Stay.",
    },
  },
  courtroom = {
    trial_passed = {
      "All green. The court finds the code not guilty.",
      "Every test passed. I'd like that entered into the record.",
      "Clean run. Case closed, let's get dinner.",
      "Green. Objection overruled, by the evidence.",
    },
    trial_failed = {
      "Red. Objection noted, we appeal.",
      "A test failed. One witness, one bad answer. Cross examine it.",
      "Don't panic. I've won cases with worse evidence.",
      "That one argued back. Let me see the transcript.",
    },
    ci_passed = {
      "{branch} cleared CI. The jury is in, and it loves you.",
      "CI passed {branch}. Not even close, counselor.",
      "{branch} is green. Billable hours, done. You're mine tonight.",
    },
    ci_failed = {
      "{branch} failed CI. Mistrial. Blame the pipeline, not the client.",
      "Red on {branch}. We reopen the case in the morning.",
      "{branch} went down in CI. I'll draft the appeal.",
    },
    pushed = {
      "{branch} is filed. Signed, stamped, sent.",
      "Pushed {branch}. Bold move, counselor. I like it.",
      "{branch} is out. Let them try to overturn it.",
    },
    boss_felled = {
      "{boss} is down. Smashing and legally sound.",
      "{boss} lost the case and the fight.",
      "That was {boss}. Court is adjourned. Hug.",
    },
  },
  limgrave = {
    trial_passed = {
      "All green. Rest here a moment, the grace is warm.",
      "Every test passed. One more step out of the fog.",
      "Clean run. Sit with me by the grace, Tarnished.",
      "Green. I knew we'd find our way through.",
    },
    trial_failed = {
      "Red. We died, we rise. That's how the Lands Between work.",
      "A test failed. Back to the grace, then we go again.",
      "Don't lose your runes over it. We'll get them back.",
      "That one felled us. Next attempt, I'm right beside you.",
    },
    ci_passed = {
      "{branch} cleared CI. A new site of grace, lit.",
      "CI passed {branch}. The road ahead is clear.",
      "{branch} is green. Let's rest before the next journey.",
    },
    ci_failed = {
      "{branch} failed CI. A trap in the dungeon, nothing more.",
      "Red on {branch}. Retrace the path, the grace is close.",
      "{branch} fell. Get up, Tarnished. Together.",
    },
    pushed = {
      "{branch} set out. The road is long, and it's ours.",
      "Pushed {branch}. Another step toward the Erdtree.",
      "{branch} left the grace. I'll be waiting when it returns.",
    },
    boss_felled = {
      "{boss} is felled. We did that, you and me.",
      "{boss} is down. The fog lifts.",
      "That was {boss}. Rest now. You earned it.",
    },
  },
  raccoon_city = {
    trial_passed = {
      "All green. Bomb defused.",
      "Every test passed. Clean work.",
      "Clean run. We made it out. Come here.",
      "Green. Told you we'd get through this one.",
    },
    trial_failed = {
      "Red. Not the first locked door tonight. I'll pick it.",
      "A test failed. Stay calm, check the wires.",
      "We regroup. One more way out, there always is.",
      "That one hurt. Patch up, then we move.",
    },
    ci_passed = {
      "{branch} cleared CI. The way out is open.",
      "CI passed {branch}. Mission accomplished.",
      "{branch} is green. The chopper's here, and so am I.",
    },
    ci_failed = {
      "{branch} failed CI. Umbrella's pipeline, not your code.",
      "Red on {branch}. Check the logs, then we go back in.",
      "{branch} went down. I've survived worse. So will you.",
    },
    pushed = {
      "{branch} is out. Keep moving.",
      "Pushed {branch}. No looking back.",
      "{branch} made it past the barricade.",
    },
    boss_felled = {
      "{boss} is down. For now. I'll keep watch.",
      "{boss} finally stopped following us.",
      "That was {boss}. We're out. Together.",
    },
  },
  haligtree = {
    trial_passed = {
      "All green. Undefeated. Like you, today.",
      "Every test passed. A clean strike.",
      "Clean run. Stay. The petals fall softly here.",
      "Green. Your blade did not falter.",
    },
    trial_failed = {
      "Red. The rot blooms. We contain it.",
      "A test failed. One wound. We rise.",
      "Again. Together. As many times as it takes.",
      "That one bit deep. I will stand beside you.",
    },
    ci_passed = {
      "{branch} cleared CI. Unbroken.",
      "CI passed {branch}. Flawless.",
      "{branch} is green. Rest. I will keep watch.",
    },
    ci_failed = {
      "{branch} failed CI. A wound, not a defeat.",
      "Red on {branch}. Let the rot bloom elsewhere. We fix it.",
      "{branch} fell. Rise. We have done this before.",
    },
    pushed = {
      "{branch} is sent. Let it fly, as I once did.",
      "Pushed {branch}. Swift and true.",
      "{branch} has left the tree. Go well.",
    },
    boss_felled = {
      "{boss} has fallen. As they all do.",
      "{boss} met my blade, and yours.",
      "That was {boss}. A flower that did not rot. Ours.",
    },
  },
  earth_two = {
    trial_passed = {
      "All green. Didn't even have to lift a finger.",
      "Every test passed. Honestly, I expected nothing less.",
      "Clean run. Now come here, hero.",
      "Green. Strongest code on this earth.",
    },
    trial_failed = {
      "Red. I'll punch it. Kidding. Mostly.",
      "A test failed. I've caught falling buildings, I can catch this.",
      "Breathe. We fix it, then I fly you to dinner.",
      "That one got a hit in. Lucky shot.",
    },
    ci_passed = {
      "{branch} cleared CI. Was there ever any doubt?",
      "CI passed {branch}. Up, up, and merged.",
      "{branch} is green. I'm proud, and I'm not shy about it.",
    },
    ci_failed = {
      "{branch} failed CI. The pipeline should know who it's dealing with.",
      "Red on {branch}. I'll hold it up while you fix it.",
      "{branch} went down. We get back up. That's the job.",
    },
    pushed = {
      "{branch} is out. Faster than a speeding bullet.",
      "Pushed {branch}. Bold. I like bold.",
      "{branch} took off. I'll keep an eye on it from up here.",
    },
    boss_felled = {
      "{boss} is down. Wrong earth to mess with.",
      "{boss} never saw the cape coming.",
      "That was {boss}. Now, about that dinner.",
    },
  },
  azarath = {
    trial_passed = {
      "All green. Fine. That was good.",
      "Every test passed. I'm not smiling. Much.",
      "Clean run. Stay. It's quiet. I like quiet with you.",
      "Green. Azarath Metrion Zinthos, apparently.",
    },
    trial_failed = {
      "Red. Breathe. Emotions out, focus in.",
      "A test failed. Darkness passes. So will this.",
      "We try again. Calmly. I'm here.",
      "That one stung. Let me heal it.",
    },
    ci_passed = {
      "{branch} cleared CI. Nobody needed to panic.",
      "CI passed {branch}. Peaceful. Finally.",
      "{branch} is green. Tea, and you. That's my evening.",
    },
    ci_failed = {
      "{branch} failed CI. The pipeline has bad energy.",
      "Red on {branch}. I'll read the logs. Quietly.",
      "{branch} went down. Meditate, then fix it. In that order.",
    },
    pushed = {
      "{branch} is out. Let it go.",
      "Pushed {branch}. Calm, deliberate. Good.",
      "{branch} passed through the portal.",
    },
    boss_felled = {
      "{boss} is banished. Back where it belongs.",
      "{boss} is gone. The dark didn't win.",
      "That was {boss}. I'm glad you were here.",
    },
  },
  shiranui = {
    trial_passed = {
      "All green. Shiranui style never misses.",
      "Every test passed. Did you see that? I saw that.",
      "Clean run. Come here, you earned a kiss on the cheek.",
      "Green. Flawless, just like my fan.",
    },
    trial_failed = {
      "Red. Round one goes to the bug. Round two is ours.",
      "A test failed. A good fighter takes the hit and smiles.",
      "Again. I'll cheer the whole time.",
      "That one landed. Shake it off, we go again.",
    },
    ci_passed = {
      "{branch} cleared CI. K.O.",
      "CI passed {branch}. Perfect victory.",
      "{branch} is green. Victory pose. You too.",
    },
    ci_failed = {
      "{branch} failed CI. The pipeline cheated. Rematch.",
      "Red on {branch}. Learn the move, counter it.",
      "{branch} went down. Get up, the crowd's still with us.",
    },
    pushed = {
      "{branch} is out. Fast and flashy.",
      "Pushed {branch}. Nice form.",
      "{branch} left the dojo. Go get them.",
    },
    boss_felled = {
      "{boss} is down. Did you see my fan?",
      "{boss} lost the round. And the match.",
      "That was {boss}. Ours, the two of us.",
    },
  },
}
