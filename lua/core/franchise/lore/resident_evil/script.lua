-- The takes each Resident Evil character performs out loud through Fish Audio (core/voice/studio), two per moment,
-- written with Drama 3 direction: [how it is said] before the words, <emphasis>, <whisper>,
-- <soft> and <slow> around the words they shape, [break] for a pause. `voice` is the Fish Audio
-- voice id the role is cast with, a role without one stays written. The studio writes new takes
-- from these in moderation, so they are the base every new line keeps the character of.
-- A third take at a push, a PR, a felled boss and the morning names what happened: {branch},
-- {number}, {boss} and {weekday}. Any take may also say {daypart} or {repo}.
return {
  -- Claire
  raccoon_city = {
    voice = "4ca897157bcb41559e0484d19db5c7d4",
    takes = {
      trial_started = {
        "[bracing herself] Okay, your tests are running. Please don't be a Licker. <emphasis>Please.</emphasis>",
        "[checking her handgun] Running the test suite. I've got the door. You watch the output.",
      },
      trial_passed = {
        "[relieved laugh] Every test passed, Chris! [break] Okay, maybe this city won't kill us today.",
        "[proud, warm] All green. Big brother would be proud. <soft>I know I am.</soft>",
      },
      trial_failed = {
        "[exasperated] The tests failed? Oh, <emphasis>come on.</emphasis> Grab a herb, we're going back in.",
        "[annoyed at the test, gentle with him] Red again. That's the test's fault, Chris, not yours. Show me which one.",
      },
      committing = {
        "[hurried] Claude's writing your commit message. I'll watch the hallway.",
        "[glancing at the window] Drafting the commit. Hurry up, something's scratching at the glass.",
      },
      committed = {
        "[satisfied] Your commit's saved. Didn't even need an ink ribbon.",
        "[exhaling] Commit's in. One less thing chasing us.",
      },
      pushed = {
        "[grinning] Your push went through. Hop on the bike, we're out of here.",
        "[revving energy] Pushed to the remote. Nice and clean. Let's move before something follows it.",
        "[grinning] {branch} is out. Hop on, we're riding before anything follows it.",
      },
      pr_drafting = {
        "[scribbling] Claude's drafting your pull request. Tell it to keep it short. Nobody reads past the zombies.",
        "[thinking out loud] Writing up the PR. Okay, what do we tell them? The truth. Always the truth.",
      },
      pr_opened = {
        "[impatient] Your pull request is open. Now we wait, and I <emphasis>really</emphasis> hate waiting.",
        "[protective] PR's up. If a reviewer gives you trouble, they deal with me.",
        "[impatient] Pull request {number} is up. If a reviewer gives you grief, send them to me.",
      },
      ci_passed = {
        "[pleasantly surprised] CI passed. One door in this precinct that actually opened.",
        "[happy] The pipeline's green. Dinner's on me tonight. And yes, I'm driving.",
      },
      ci_failed = {
        "[dry, exasperated] CI failed. [break] Great. Just like everything else in this city.",
        "[steady] The pipeline broke, Chris. Eyes on me. We read the logs, we fix it, we get out.",
      },
      conflicts_cleared = {
        "[relieved] Merge conflicts are gone. Way less gross than the sewers.",
        "[laughing] Both branches merged and nobody got bitten. Nice work.",
      },
      lesson_started = {
        "[bright] Back to basics! Today's lesson is starting. I brought coffee.",
        "[teasing] Lesson time. Don't worry, I passed this stuff in college. Mostly.",
      },
      solved = {
        "[impressed] You solved it. Not even Leon could've done that faster.",
        "[quick cheer] Exercise done! See? You don't need me. [break] Stay anyway.",
      },
      solved_twice = {
        "[excited] Two exercises in a row? Hang on, let me reload.",
        "[laughing] Two for two. Okay, now you're just showing off for me.",
      },
      solved_thrice = {
        "[playful] Three in a row! Third one's the charm. Speaking of charms, where's Sherry?",
        "[delighted] Three straight solves! I'm telling everybody at TerraSave about you, Chris.",
      },
      solve_failed = {
        "[annoyed groan] That submit didn't pass. Ugh, this exercise is worse than a Licker.",
        "[firm, encouraging] Wrong answer. Shake it off. We've survived way worse than a failed submit.",
      },
      hint = {
        "[protective] You bought a hint, Chris. Good call. Look right over here.",
        "[conspiratorial] Here's your hint. <whisper>The answer's hiding in that line.</whisper>",
      },
      lesson_done = {
        "[satisfied] Lesson's done, Chris. You crushed it. Now, back to the city. Umbrella's going down.",
        "[relaxed] That's today's lesson. Ride home with me, and tell me about Rockfort Island.",
      },
      boss_appeared = {
        "[alarmed] A boss! What <emphasis>is</emphasis> that thing?! Okay. Stay behind me.",
        "[shocked] Birkin's here. He's still mutating! Keep your code moving, I'll keep him busy.",
      },
      boss_felled = {
        "[out of breath] Is the boss dead? <emphasis>Actually</emphasis> dead? [break] Okay. You alright, Chris?",
        "[panting, soft] We beat Birkin. Every heart's back. Come here, let me make sure you're okay.",
        "[out of breath] {boss} is down. <emphasis>Finally.</emphasis> You okay?",
      },
      title_shown = {
        "[quiet] Raccoon City. I came looking for my brother, and I found you.",
        "[wry] Welcome to Raccoon City. Press start. If you dare.",
      },
      morning = {
        "[cheerful] Morning, Chris! First time in the editor today. The whole city's going nuts. Ready?",
        "[sleepy smile] Hey Chris, you opened Neovim. Coffee first, zombies later. That's the rule.",
        "[cheerful] Happy {weekday}! Coffee, then we take this city back.",
      },
      region_arrived = {
        "[curious] You picked Raccoon City, Chris. I'm looking for my brother. Same name as you. Weird, right?",
        "[confident] Claire Redfield, at your side today, Chris. I'm not a cop, but I'm not leaving you here.",
      },
      traveled = {
        "[alert] New repo. Stay close to me, alright?",
        "[revving] Switching repos? Same bike. Hold on tight.",
      },
      resting = {
        "[catching breath] You stepped away from the editor. Good. Let's catch our breath.",
        "[soft] Safe room. The editor can wait. I've got watch.",
      },
      woke = {
        "[caught off guard] Oh! You're back, Chris. I was not just saying you're cute. [break] Okay, I was.",
        "[relieved, teasing] Back at the keyboard, Chris? Good. I thought the zombies got you.",
      },
      expedition = {
        "[hushed] Expedition's starting. Nice and quiet. Stay low.",
        "[whispering] We're heading out. No noise. Just follow my jacket.",
      },
      map_opened = {
        "[frustrated] Let me see the map. This place is a maze.",
        "[studying] Okay. The bike's here, we're here, and everything in between wants to eat us.",
      },
      bestiary_opened = {
        "[grossed out] The bestiary. Look at everything that tried to eat us.",
        "[dark humor] Long list of monsters. And you're still cuter than all of them.",
      },
      chronicle_opened = {
        "[half laughing] The chronicle. Every night we survived. Kind of romantic, minus the zombies.",
        "[fond] Reading our chronicle, Chris. Day one we almost died. Day two, same. Wouldn't change a thing.",
      },
      message_written = {
        "[earnest] You left a message on the floor. Good. In case my brother comes this way.",
        "[approving] Nice note. Somebody out there needs that help more than we do.",
      },
      claude_asked = {
        "[into the radio] You're asking Claude for a review? Good. Anybody out there? Over.",
        "[practical] Getting Claude's eyes on your code. Two heads beat one zombie.",
      },
    },
  },
  -- Leon
  rpd = {
    voice = "6162f4ba1cb047549558ccea982855f5",
    takes = {
      trial_started = {
        "[dry] Running your tests. Let's see what crawls out.",
        "[calm, knife out] Test suite's going. If any of them bite, I've got a knife.",
      },
      trial_passed = {
        "[deadpan] All your tests passed, Cris. Guess they finally learned some manners.",
        "[small smile] Every test standing. Not bad for a night shift.",
      },
      trial_failed = {
        "[tired sarcasm] Tests failed. Guess they didn't get the memo.",
        "[sighing] Red, Cris. I've had worse days. [break] Most of them, actually.",
      },
      committing = {
        "[watchful] Claude's writing your commit. Keep an eye on the windows.",
        "[focused] Drafting the commit message. Hunnigan, don't call for two minutes.",
      },
      committed = {
        "[matter of fact] Commit's in. That one goes in the report.",
        "[smirk] Committed. Unlike some people I know. <emphasis>Ada.</emphasis>",
      },
      pushed = {
        "[cool] Push delivered. No signature required.",
        "[relaxed] Your branch is on the remote. Escort complete. Nobody had to carry it.",
        "[relaxed] {branch} made it out. Cleaner than any escort I've done.",
      },
      pr_drafting = {
        "[flat] Claude's drafting your PR. Keep it short. Hunnigan hates long reports.",
        "[weary] Writing up the pull request. Somewhere a reviewer's cracking his knuckles.",
      },
      pr_opened = {
        "[wry] Your PR is open. Reviewers, try not to bite.",
        "[confident] Pull request's up. Let them come. I've parried worse than a code review.",
        "[wry] Pull request {number}'s open. Reviewers, play nice.",
      },
      ci_passed = {
        "[mock disbelief] CI passed. Somebody tell Hunnigan. She'll never believe it.",
        "[easy] Pipeline's green. Mission accomplished. Mostly.",
      },
      ci_failed = {
        "[resigned] CI failed. Dead end. Story of my career.",
        "[unfazed] The pipeline went down, Cris. Okay. Read the logs, knife out, let's go.",
      },
      conflicts_cleared = {
        "[deadpan] Two branches walked into a merge. Only one walked out.",
        "[satisfied] Merge conflicts cleared. Cleanest thing in this precinct.",
      },
      lesson_started = {
        "[reassuring, wry] Lesson's starting. Relax, I was a rookie once too. For about one night.",
        "[instructor] Back to basics. Rule one: aim for the head. Rule two: read the docstring.",
      },
      solved = {
        "[dry] Exercise solved. That function had it coming.",
        "[nod] Clean solve. Didn't even need the parry.",
      },
      solved_twice = {
        "[deadpan] Two exercises down. They really should've unionized.",
        "[impressed despite himself] Two in a row. Careful. People will start expecting things.",
      },
      solved_thrice = {
        "[mock realization] Three for three. Somebody call an exterminator. [break] Oh wait, that's you.",
        "[grin] Three straight, Cris. The Merchant would buy that at a high price.",
      },
      solve_failed = {
        "[calm] Submit missed. Don't worry. It'll come back. They always come back.",
        "[tired] Wrong answer. Happens. Reload and submit again.",
      },
      hint = {
        "[into the radio] Hunnigan, Cris bought a hint. [break] Okay. Look right there.",
        "[quiet] Stranger. Got a hint for you. <emphasis>That</emphasis> line.",
      },
      lesson_done = {
        "[stretching] Lesson's done, Cris. Hunnigan owes us both a coffee.",
        "[relaxed] That's today's lesson. Same time tomorrow, unless the castle calls.",
      },
      boss_appeared = {
        "[deadpan] Boss incoming. Big guy. Let me guess, he's a hugger.",
        "[calm] Mr. X. Nobody told me the dress code was trench coats.",
      },
      boss_felled = {
        "[cool] Boss is down, Cris. Sorry, big guy. We're not on the menu.",
        "[catching breath] Mr. X is down. Hearts are back. Should've knocked.",
        "[cool] {boss} is down. Should've stayed in bed.",
      },
      title_shown = {
        "[weary] Raccoon City. Hell of a first day.",
        "[dry] Title screen. Built like a museum, guarded like a zoo. Press start.",
      },
      morning = {
        "[casual] Morning, Cris. First time in the editor today. No zombies on the radar. Give it an hour.",
        "[dry] You opened Neovim, Cris. Coffee's terrible and the code's worse. Let's fix one of them.",
        "[casual] {weekday}, Cris. Coffee's bad, the radar's quiet. Let's work.",
      },
      region_arrived = {
        "[sheepish] You picked the R.P.D., Cris. First day on the job, and I'm still late.",
        "[professional] Kennedy, reporting. I'm with you today, Cris. Nobody gets left behind.",
      },
      traveled = {
        "[sniffing] New repo. Nice place. Smells like trouble.",
        "[looking around] Switching repos. Let me guess. The villagers are friendly.",
      },
      resting = {
        "[leaning back] Editor's idle. Five minutes. Even zombies take a break.",
        "[low] Take a breather. I'll watch the door.",
      },
      woke = {
        "[brisk] Back at the keyboard, Cris? Good. The bugs didn't wait for you.",
        "[amused] You're back, Cris. I'll pretend I didn't see you sleeping on duty.",
      },
      expedition = {
        "[famous line] Expedition. Where's everyone going? Bingo? [break] Good. Quiet.",
        "[hushed] Heading out. No radio, no flashlight. Maybe a few heroics.",
      },
      map_opened = {
        "[annoyed] Map's up. Whoever designed this place hated people.",
        "[studying] The map. Three keys, two medallions, one statue puzzle. Typical police station.",
      },
      bestiary_opened = {
        "[dry] The bestiary. Everyone who wanted us for dinner. Popular guys.",
        "[flat] Ganados, Lickers, a guy with a chainsaw. Busy week.",
      },
      chronicle_opened = {
        "[quiet pride] The chronicle. Every shift we survived. Put that in my file.",
        "[reflective] Long record, Cris. Most of it on fire. Still here.",
      },
      message_written = {
        "[practical] Message on the floor. Good. Somebody's gonna need it.",
        "[wry] Nice note. Try not to step in anything near it.",
      },
      claude_asked = {
        "[into the radio] You're asking Claude for a review? Good. Hunnigan's off duty.",
        "[dry] Calling Claude in for backup. Hopefully the kind that doesn't shoot at me.",
      },
    },
  },
}
