-- What the character of each location says when something happens, written from the voice sheets in
-- docs/voices/resident_evil.md. {branch}, {boss} and {number} are filled in when the moment has
-- them.
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
    committed = {
      "Committed. One less thing to worry about.",
      "Saved on {branch}. Okay, what's next?",
      "Locked in. Good call.",
    },
    pr_opened = {
      "PR #{number} is up. Let's see if anyone actually reads it.",
      "#{number} is out there. I'll watch your back while they review.",
      "PR #{number}. Nice. Now we wait, and I hate waiting.",
    },
    region_arrived = {
      "Claire here. Raccoon City's a mess, but we've got this.",
      "Okay, I'm with you today. Let's get through this together.",
      "Raccoon City. Stay close, keep moving.",
    },
    morning = {
      "Hey, you're back. Coffee first, zombies later.",
      "Morning. Same city, new day. Let's go.",
      "You made it through the night. Good. Now let's work.",
    },
    conflicts_cleared = {
      "Conflicts gone. Told you we'd get out of there.",
      "Merge is clean. That was close.",
      "No more conflicts. Let's not do that again.",
    },
    woke = {
      "You're up. Good, I was getting worried.",
      "Back? Okay, let's keep moving.",
      "Rested? Good. We've still got a city to get out of.",
    },
    -- what Claire says out loud, each clip in sounds/resident_evil/voices/raccoon_city/
    spoken = {
      morning = { morning = "Hey Christopher, the whole city is going nuts. Ready for today?" },
      region_arrived = {
        region_arrived = "I'm looking for my brother Chris. Hey, you have the same name. Weird.",
      },
      lesson_started = { lesson_started = "Hey Chris, ready for today's lesson?" },
      lesson_done = {
        lesson_done = "You crushed today's lesson. Now, let's get back to the city. Umbrella is going down.",
        lesson_done_2 = "Alright, another day behind us. Now, tell me more about Rockfort Island.",
      },
      solved = { solved = "Not even Leon could have done that better. On to the next one." },
      solved_twice = { solved_twice = "Twice in a row? Awesome. Let me reload." },
      solved_thrice = {
        solved_thrice = "Okay, show off. Third one's the charm. Speaking of charms, where's Sherry?",
      },
      hint = { hint = "Don't worry, let me help you." },
      boss_appeared = { boss_appeared = "Okay, handsome. We'll go through this together, okay?" },
      resting = { resting = "Let's catch our breath, just for a minute." },
      woke = {
        woke = "Don't tell Elizabeth, but I think you're kind of cute. Wait, did you hear that?",
      },
      expedition = { expedition = "Okay, nice and quiet." },
      traveled = { traveled = "Stay close to me, alright?" },
      returned = { returned = "This place again, fine. I know the way." },
      committing = { committing = "Working on that commit, cover me!" },
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
    committed = {
      "Committed. Rookie mistake to wait any longer.",
      "Saved on {branch}. Not bad for a first day.",
      "Locked in. That one goes in the report.",
    },
    pr_opened = {
      "PR #{number}. Hope the reviewers aren't infected.",
      "#{number} is up. Somebody call for backup.",
      "PR #{number}. Let's see who opens fire first.",
    },
    region_arrived = {
      "Leon Kennedy, RPD. Guess this is my precinct today.",
      "Welcome to the RPD. Don't touch the statues.",
      "First day on the job, again. Let's make it count.",
    },
    morning = {
      "Morning. No zombies yet. Give it time.",
      "You're back. The coffee's terrible and the code's worse. Let's fix one.",
      "New day, same precinct. Where do we start?",
    },
    conflicts_cleared = {
      "Conflicts cleared. That's one way to clean up a precinct.",
      "Merge is clean. Nobody got bit.",
      "No more conflicts. I'll write it up in the report.",
    },
    woke = {
      "Back on your feet? Good, the night shift is brutal.",
      "You're up. I'll pretend I didn't see you sleeping on duty.",
      "Rested. Good. Let's finish this before sunrise.",
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
    committed = {
      "Committed. Everything's in its place.",
      "Saved on {branch}. Clean and by the book.",
      "Locked in. One more door unlocked.",
    },
    pr_opened = {
      "PR #{number} is up. Let's see if the team holds.",
      "#{number} filed. I'll check every corner while they read.",
      "PR #{number}. Methodical. I like it.",
    },
    region_arrived = {
      "Jill Valentine, S.T.A.R.S. The mansion is ours to clear today.",
      "Spencer Mansion. Stay sharp, every room has a trick.",
      "I'm with you today. Let's do this right.",
    },
    morning = {
      "Morning. Map's out, ammo's checked. Let's go.",
      "You're back. The mansion didn't get any friendlier.",
      "New day. One room at a time.",
    },
    conflicts_cleared = {
      "Conflicts cleared. The lock almost picked itself.",
      "Merge is clean. That's how S.T.A.R.S. does it.",
      "No conflicts left. Every door opens now.",
    },
    woke = {
      "You're up. Good timing, I just finished the sweep.",
      "Rested? Then let's keep moving.",
      "Back with me. The mansion's quiet. For now.",
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
    committed = {
      "Committed. A minor step in a grand design.",
      "{branch} recorded. Even you can be useful.",
      "Saved. Do not make me regret it.",
    },
    pr_opened = {
      "PR #{number}. Let the lesser minds review it.",
      "#{number} submitted. Their opinion is irrelevant.",
      "PR #{number}. All according to plan.",
    },
    region_arrived = {
      "Albert Wesker. Consider yourself fortunate to work under me today.",
      "The lab is mine. You may use it.",
      "Welcome to Umbrella. Try to keep up.",
    },
    morning = {
      "You return. I have been awake for hours.",
      "Morning. Sleep is a weakness I outgrew.",
      "A new day. Another chance to prove yourself adequate.",
    },
    conflicts_cleared = {
      "The conflicts are resolved. Only the superior version survives.",
      "Merge complete. Inferior lines eliminated.",
      "No conflicts. As expected.",
    },
    woke = {
      "Finally awake. Time is a resource, and you squander it.",
      "You rested. How very human.",
      "Rise. My patience is not infinite.",
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
    committed = {
      "Committed. Quiet and clean, just how I like it.",
      "Saved on {branch}. No witnesses.",
      "Locked in. Don't get sentimental about it.",
    },
    pr_opened = {
      "PR #{number}. Let's see who bites.",
      "#{number} delivered. I'll be watching from the rafters.",
      "PR #{number}. Not bad. Not bad at all.",
    },
    region_arrived = {
      "Ada Wong. Don't ask what I'm doing here.",
      "The island. Keep your head down, I'll handle the rest.",
      "Miss me? You can admit it.",
    },
    morning = {
      "Back already? You must like me.",
      "Morning. I've been up since the island woke.",
      "New day. Same job. Different angle.",
    },
    conflicts_cleared = {
      "Conflicts gone. Clean exit.",
      "Merge settled. I'd have done it faster.",
      "No conflicts left. You're learning.",
    },
    woke = {
      "Rested? Don't make it a habit.",
      "You're up. I almost left without you.",
      "Awake. Good. I need a getaway driver.",
    },
  },
}
