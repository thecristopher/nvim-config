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
