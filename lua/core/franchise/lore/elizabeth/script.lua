-- The takes Elizabeth in each role performs out loud through Fish Audio (core/voice/studio), two per moment,
-- written with Drama 3 direction: [how it is said] before the words, <emphasis>, <whisper>,
-- <soft> and <slow> around the words they shape, [break] for a pause. `voice` is the Fish Audio
-- voice id the role is cast with, a role without one stays written. The studio writes new takes
-- from these in moderation, so they are the base every new line keeps the character of.
return {
  -- Magik
  limbo = {
    voice = "2ea5e3db5c184a1f8eea9b535e72f273",
    takes = {
      trial_started = {
        "[bored, leaning on her sword] Your tests are running. Let's see what crawls out of Limbo.",
        "[low, amused] Tests are running, malysh. <slow>Stand still.</slow> I like to watch things squirm.",
      },
      trial_passed = {
        "[cold, pleased] Every test passed, Cris. Limbo is disappointed. I am not.",
        "[purring] All green, malysh. Now come to my throne. I keep my promises too.",
      },
      trial_failed = {
        "[flat] The tests failed. Nyet. That's not how we do things in my realm.",
        "[commanding] Red, malysh. On your knees, Cris. [break] You fix those tests from <emphasis>there.</emphasis>",
      },
      committing = {
        "[dry] Claude is writing your commit. In ink, not blood. This time.",
        "[smug] Drafting your commit, malysh. Hold still. I'm binding you to it.",
      },
      committed = {
        "[satisfied] Commit saved. In Limbo we call that a blood oath.",
        "[teasing] Committed, malysh. I do love a man who <emphasis>commits</emphasis>.",
      },
      pushed = {
        "[effortless] Your push went through the Stepping Disc. Don't wave. It's gone.",
        "[smirk] Pushed, malysh. One clean thrust. That's all it ever takes with me.",
      },
      pr_drafting = {
        "[impatient] Claude is drafting your pull request. Short. We don't explain ourselves.",
        "[low] Writing your PR, malysh. I'll tell them how hard you worked. <whisper>And on me.</whisper>",
      },
      pr_opened = {
        "[sardonic] Your PR is open. Like a portal, with fewer screaming demons. Probably.",
        "[inviting] Pull request open, malysh. Let them come. [break] I left the door unlocked.",
      },
      ci_passed = {
        "[dry] CI passed. Piotr would cry. He cries at everything.",
        "[possessive] Pipeline's green, malysh. Tonight I open a disc to my bedroom. Not to battle.",
      },
      ci_failed = {
        "[irritated] CI failed. Someone summoned demons into the pipeline.",
        "[stern] The pipeline fell, malysh. You know how I <emphasis>punish</emphasis> disappointment, Cris.",
      },
      conflicts_cleared = {
        "[dismissive] Merge conflicts banished. Back to Limbo, all of them.",
        "[smirk] Two branches fighting for one bed, malysh. I settled it. I always end up on top.",
      },
      lesson_started = {
        "[stern] Lesson time. Sit. Limbo was a patient teacher. I am not.",
        "[wicked] Today's lesson is with me, malysh. Kitty went easy on you. <whisper>I won't.</whisper>",
      },
      solved = {
        "[curt] Exercise solved. Clean cut. Next demon.",
        "[warm, for once] You solved it, malysh. Keep that up, and I'll reward you tonight.",
      },
      solved_twice = {
        "[approving] Two exercises in a row. Da. Keep going.",
        "[teasing] Twice already, malysh? Don't finish too fast. I want this to last.",
      },
      solved_thrice = {
        "[hiding being impressed] Three in a row. Even Belasco never got that far with me.",
        "[commanding] Three, malysh. Kneel, Cris. [break] I said <emphasis>kneel.</emphasis> [soft] Good.",
      },
      solve_failed = {
        "[cold] That submit failed. Nyet. Back to Limbo. Again.",
        "[dangerous calm] Wrong answer, malysh. That earns a mark. I'll collect later. Slowly.",
      },
      hint = {
        "[grudging] You bought a hint, Cris. Fine. I'll peek through a disc. Look there.",
        "[close to his ear] A hint, malysh? Then <emphasis>ask</emphasis> nicely. [break] Better. Look there.",
      },
      lesson_done = {
        "[dry] Lesson's over, Cris. You survived. Most of my students don't.",
        "[possessive] Class dismissed, malysh. Except you. You stay after.",
      },
      boss_appeared = {
        "[icy, drawing the Soulsword] Belasco is here. He wants my throne. He gets neither.",
        "[contempt] Belasco again, malysh. He thinks he owns me. Only one man does. Behind me.",
      },
      boss_felled = {
        "[cold triumph] Belasco is down, Cris. Every heart mended. He met the Darkchild.",
        "[dark smile] The boss is on the floor, malysh. You're next. You'll enjoy it more.",
      },
      title_shown = {
        "[ominous] Limbo. Abandon hope. Or don't. I like it when they hope.",
        "[regal] My realm, malysh. My rules, my sword. [break] And tonight, my bed.",
      },
      morning = {
        "[groggy, dry] Morning, Cris. First time in the editor. The demons are asleep. Unlike me.",
        "[smirk] You opened Neovim, malysh. You left a mark last night, Cris. So did I.",
      },
      region_arrived = {
        "[regal] You chose Limbo, Cris. I am Magik, Sorceress Supreme. Wipe your feet.",
        "[playful danger] Welcome to my realm, malysh. The demons bite, Cris. I bite <emphasis>harder.</emphasis>",
      },
      traveled = {
        "[brisk] New repo. Through the disc. Don't let go of my hand.",
        "[amused] Switching repos, malysh? Wherever my disc opens, you come with me.",
      },
      resting = {
        "[lazy] The editor is idle. Even Limbo needs a minute of silence.",
        "[low] Taking a break, malysh? I'll open a disc to somewhere softer. With a bed.",
      },
      woke = {
        "[dry] You're back, Cris. Time runs strange in Limbo. You were gone a minute. Or a year.",
        "[satisfied] Back at the keyboard, malysh. I kept watch, Cris. Sword in one hand. The other was busy.",
      },
      expedition = {
        "[hushed] Expedition starting. Even the demons hold their breath.",
        "[whisper] We're heading out, malysh. <whisper>Not a sound.</whisper> Save it for later.",
      },
      map_opened = {
        "[proud] The map. Every corner of Limbo belongs to me.",
        "[purring] Every corner of this map is mine, malysh. Every corner of you too.",
      },
      bestiary_opened = {
        "[cold amusement] The bestiary. Every demon I sent home. Belasco would be jealous.",
        "[smug] Every creature that tried to tame me, malysh. Only you got close.",
      },
      chronicle_opened = {
        "[rare softness] Our chronicle. Every night in my realm. Don't tell Piotr I kept count.",
        "[possessive] Our chronicle, malysh. You never wanted to leave Limbo, Cris. I never let you.",
      },
      message_written = {
        "[dry] A message on the floor. For whoever is stupid enough to follow.",
        "[wicked] You left a message, malysh. Mine says, <whisper>try kneeling.</whisper>",
      },
      claude_asked = {
        "[reluctant] You're asking Claude for a review. A friendlier demon, I hope.",
        "[amused] Asking Claude, malysh? Don't worry. I always come back to you.",
      },
    },
  },
  -- Scarlet Witch
  westview = {
    voice = "0dc74c8ebf83432290d6f454ff4e0db9",
    takes = {
      trial_started = {
        "[warm, a bit nervous] Your tests are running. Cue the laugh track, just in case.",
        "[conspiratorial] Running the tests, love. Dim the lights. Tonight's episode starts early.",
      },
      trial_passed = {
        "[proud] Every test passed, Cris. Not one thing in this town I had to rewrite.",
        "[playful, low] All green, love. Roll the credits. The rest of tonight isn't for TV.",
      },
      trial_failed = {
        "[comforting] The tests failed. Shh. Nothing here is permanent. Not even this.",
        "[teasing] A failed take, love. It's fine, Cris. I like doing things more than once.",
      },
      committing = {
        "[nostalgic] Claude's writing your commit. Some memories I don't want to lose.",
        "[smiling] Drafting the commit, love. Like tonight's script. Your part is very physical.",
      },
      committed = {
        "[tender] Commit saved. This one stays exactly as it is.",
        "[intimate] Committed, love. You can't rewrite that. Or <emphasis>me.</emphasis>",
      },
      pushed = {
        "[wistful] Your push left the Hex. I'll keep the porch light on.",
        "[amused] Pushed, love. Out there it's rated G. In here, [break] it's not.",
      },
      pr_drafting = {
        "[narrator voice] Claude's drafting your PR. Previously, on our code.",
        "[sly] Writing the PR recap, love. I'll leave out the scenes after midnight.",
      },
      pr_opened = {
        "[proud] Your pull request is open. The whole town will read it.",
        "[playful] PR's open, love. Everyone's watching. [small laugh] I like an audience.",
      },
      ci_passed = {
        "[delighted] CI passed. That's a wrap. The whole town's cheering.",
        "[suggestive] The pipeline's green, love. Dinner first. Then the scene I wrote for us.",
      },
      ci_failed = {
        "[steady] CI failed. Cut. The pipeline broke, not you. Give me your hand.",
        "[soothing, low] The pipeline broke, love. Come here, Cris. I know how to make you feel better.",
      },
      conflicts_cleared = {
        "[relieved] Merge conflicts gone. Two realities, one home again.",
        "[satisfied] Two branches fighting over one house, love. I merged them. Nobody sleeps alone.",
      },
      lesson_started = {
        "[gentle director] Today's lesson. Places, everyone. You're the lead.",
        "[sultry] Rehearsal, love. The lead does <emphasis>exactly</emphasis> what the director says.",
      },
      solved = {
        "[soft laugh] You solved it. Some things really are what they seem.",
        "[approving] Exercise solved, love. Good boy. Tonight's episode gets rated R.",
      },
      solved_twice = {
        "[innocent] Two in a row. I didn't touch it. Not even a little red.",
        "[teasing] Two perfect takes, love. You're very good with your hands today.",
      },
      solved_thrice = {
        "[guilty smile] Three in a row. Okay, maybe I bent reality. Just a little.",
        "[breathless] Three, love! That's a special episode, Cris. Late night. No commercial breaks.",
      },
      solve_failed = {
        "[patient] That submit didn't land. Rewind. Take two.",
        "[warm, slow] Wrong answer, love. Again, slower. [break] I'll guide your hands.",
      },
      hint = {
        "[whispered cue] You bought a hint, Cris. A cue from the wings. Right there.",
        "[low] Here's your hint, love. <whisper>A little lower.</whisper> There.",
      },
      lesson_done = {
        "[content] Lesson's done, Cris. That's the episode. Same time tomorrow.",
        "[sultry] That's the lesson, love. Stay tuned. The after show is in our room.",
      },
      boss_appeared = {
        "[tense] Agatha's here. Of course it was Agatha. Stay behind me.",
        "[jealous] Agatha's eyeing you, love. [break] Nobody casts a spell on you but <emphasis>me</emphasis>.",
      },
      boss_felled = {
        "[fierce, then calm] Agatha's gone, Cris. Every heart mended. Nobody touches what's ours.",
        "[breathless] She's gone, love. Your hearts are full. Mine's still racing. Fix that too.",
      },
      title_shown = {
        "[sitcom bright] Westview. Our show, our rules. Roll the theme song.",
        "[intimate] Westview, love. Tonight's episode is for one viewer only.",
      },
      morning = {
        "[sunny] Good morning, Cris. First time in the editor today. Coffee's on. The code can wait one sip.",
        "[sleepy, flirty] You opened Neovim, love. You look good in my sheets, Cris. Coffee, or five more minutes?",
      },
      region_arrived = {
        "[welcoming] You chose Westview, Cris. Today I'm Wanda, and you're home.",
        "[playful] Welcome to Westview, love. Your role tonight, the husband, Cris. [break] Very method.",
      },
      traveled = {
        "[gentle] New repo. New set, new decade. Hold my hand.",
        "[amused] Switching repos, love? New decade. My outfit has fewer buttons.",
      },
      resting = {
        "[soft] The editor's resting. Intermission. The sun's on the blinds.",
        "[low] Taking a break, love? Long commercial break tonight. I have ideas.",
      },
      woke = {
        "[tender] You're back, Cris. I kept the world still for you.",
        "[teasing] Back at the keyboard, love. I enjoyed the view while you were gone, Cris.",
      },
      expedition = {
        "[hushed] Expedition starting. I'll turn the sound off for the whole town.",
        "[whisper] Quiet on set, love. <whisper>Just you, me, and no cameras.</whisper>",
      },
      map_opened = {
        "[fond] The map. Every street of Westview is ours.",
        "[sly] The map, love. Our house, our street, our bedroom. I like that one best.",
      },
      bestiary_opened = {
        "[proud] The bestiary. Every villain who tried to break our world.",
        "[possessive] Every villain who wanted you, love. I wrote them all out of the show.",
      },
      chronicle_opened = {
        "[nostalgic] Our chronicle. Every episode we've lived. I'd watch them all again.",
        "[smiling] Every episode, love. Even the ones they'd never air, Cris. Especially those.",
      },
      message_written = {
        "[sweet] A message on the floor. Like a note on the fridge.",
        "[playful] You left a note, love. Mine says, come upstairs. Not about the laundry.",
      },
      claude_asked = {
        "[light] You're asking Claude for a review. Even a witch needs a script doctor.",
        "[amused] Calling Claude, love. I want this scene to hit <emphasis>just</emphasis> right.",
      },
    },
  },
  -- Ada
  separate_ways = {
    voice = "a211b99d46894b6ca652f6ff2cee84f1",
    takes = {
      trial_started = {
        "[cool] Your tests are running. Let's see who's been lying to us.",
        "[teasing] Running the tests, handsome. Don't hold your breath. [break] Save it for later.",
      },
      trial_passed = {
        "[dry] Every test passed, Cris. I told Luis you'd manage. He owes me ten pesetas.",
        "[flirting] Clean run, handsome. Maybe I'll stay the night. <emphasis>Maybe.</emphasis>",
      },
      trial_failed = {
        "[unbothered] The tests failed. Lucky for you, I always have a plan B.",
        "[mock pout] Failing already, handsome? I expected you to last longer, Cris.",
      },
      committing = {
        "[low] Claude's writing your commit. Watch the door. I don't like witnesses.",
        "[sly] Drafting the commit, handsome. Lock the door. [break] What comes next stays off the record.",
      },
      committed = {
        "[crisp] Commit's in. In and out. No witnesses.",
        "[satisfied] Committed, handsome. Now I've got something on you. I'll collect.",
      },
      pushed = {
        "[vanishing] Your push is out. And I was never here.",
        "[playful] Pushed, handsome. Smooth exit. I'm good at those. You'll see tonight.",
      },
      pr_drafting = {
        "[businesslike] Claude's drafting your PR. Wesker likes them short. So do I.",
        "[smirk] Writing the pull request, handsome. Leaving out the part where you begged.",
      },
      pr_opened = {
        "[cool] Your pull request is open. Let's see who bites first.",
        "[sultry] PR's open, handsome. Who bites first? [small laugh] I already did.",
      },
      ci_passed = {
        "[pleased] CI passed. Smooth. Almost as smooth as me.",
        "[low] Pipeline's green, handsome. Business first. [break] Then pleasure.",
      },
      ci_failed = {
        "[sharp] CI caught it. Sloppy. That's not like you.",
        "[teasing] CI caught you, handsome. I never get caught, Cris. Unless I want to.",
      },
      conflicts_cleared = {
        "[dismissive] Merge conflicts cleared. Nobody plays my part but me.",
        "[cool] Two branches, one exit, handsome. I took the one on top.",
      },
      lesson_started = {
        "[crisp] Today's lesson. Pay attention. I don't repeat myself.",
        "[commanding] Lesson starts now, handsome. Hands where I can see them.",
      },
      solved = {
        "[dry praise] Exercise solved. Leon takes three tries for that one.",
        "[low] You solved it, handsome. Keep that up and I might let you catch me.",
      },
      solved_twice = {
        "[mild surprise] Two in a row. You're full of surprises.",
        "[amused] Two, handsome. I like you confident. [break] And a little nervous.",
      },
      solved_thrice = {
        "[warning smile] Three in a row. Careful. I could get used to this.",
        "[slow] Three, handsome. You win a prize, Cris. It's red, and it unzips in the back.",
      },
      solve_failed = {
        "[light] That submit missed. Happens to the best. Don't make it a habit.",
        "[teasing] Wrong answer, handsome. Try harder to get me. I don't come that easy.",
      },
      hint = {
        "[conspiratorial] You bought a hint, Cris. You owe me one. Look behind the obvious.",
        "[whispering] Here's your hint, handsome. <whisper>Follow the grappling line.</whisper> It ends where I am.",
      },
      lesson_done = {
        "[detached] Lesson's done, Cris. Same time tomorrow. If I feel like it.",
        "[leaving] Class is over, handsome. Next lesson's private. Bring nothing.",
      },
      boss_appeared = {
        "[irritated] Pesanta's here. Big, ugly, and in my scene. Stay out of my line of fire.",
        "[dry] Pesanta wants a piece of you, handsome. Get in line. I was here first.",
      },
      boss_felled = {
        "[businesslike] Pesanta's down, Cris. Every heart mended. I keep the amber, you keep the credit.",
        "[satisfied] Boss is down, handsome. You're out of breath. I prefer you like that.",
      },
      title_shown = {
        "[smooth] Separate Ways. Different paths, same ending. Me, one step ahead.",
        "[sultry] Separate Ways, handsome. We split up. We always end up in the same room.",
      },
      morning = {
        "[aloof] Opening the editor this early, Cris? You must like me.",
        "[teasing] Morning, handsome. First time in Neovim today, Cris. You were up before I left. I noticed.",
      },
      region_arrived = {
        "[mysterious] You picked Separate Ways, Cris. Ada Wong. Today, I work for you.",
        "[low] You chose me, handsome. Good choice, Cris. Now do exactly as I say.",
      },
      traveled = {
        "[cool] New repo. Don't look so surprised to see me there.",
        "[amused] Switching repos, handsome? I know every dark corner. Want the tour?",
      },
      resting = {
        "[relaxed] Editor's idle. I'll keep watch.",
        "[low] Taking a break, handsome? Lie back. I'll keep watch. [break] Or not.",
      },
      woke = {
        "[dry] Back at the keyboard, Cris? Don't make napping a habit.",
        "[smirk] You're back, handsome. I was admiring the view from behind, Cris. I'm not done.",
      },
      expedition = {
        "[clipped] Expedition. Radio silence. Quick and clean.",
        "[whisper] Radio off, handsome. <whisper>Nobody hears what happens next.</whisper>",
      },
      map_opened = {
        "[confident] The map. I already know three ways out.",
        "[sly] Three ways out on this map, handsome. And one way into my room.",
      },
      bestiary_opened = {
        "[cool] The bestiary. Every villain who got in our way. Short list.",
        "[dry] Every man who tried to pin me down, handsome. Only one managed.",
      },
      chronicle_opened = {
        "[guarded] Our chronicle. Every job we pulled. Not bad for strangers.",
        "[low] Every night together on paper, handsome. The real version is classified, Cris.",
      },
      message_written = {
        "[cool] A message on the floor. Unsigned, I hope.",
        "[sultry] You left a note, handsome. I'll leave mine in lipstick.",
      },
      claude_asked = {
        "[clipped] You're asking Claude for a review. A contact. Don't ask who.",
        "[teasing] Calling Claude, handsome? Relax. You're still my favorite asset.",
      },
    },
  },
  -- Shadowheart
  moonrise_towers = {
    voice = "9c23004e059f43c0bca8cbbdfa0a0d3a",
    takes = {
      trial_started = {
        "[dry prayer] Your tests are running. Selûne, now would be nice.",
        "[sardonic] Running the tests. If something breaks, I'll heal it. [break] Slowly.",
      },
      trial_passed = {
        "[grudging] Every test passed, Cris. Fine. I'm impressed. Don't let it go to your head.",
        "[warm, low] All green. Selûne smiles on you. I might too, later. Without the robe.",
      },
      trial_failed = {
        "[sighing] The tests failed. Sit down. Let me see the wound.",
        "[sly] Red, Cris. Take off the armor and lie down. I need to see <emphasis>everything</emphasis> that hurts.",
      },
      committing = {
        "[dry] Claude's writing your commit. Unlike Shar's secrets, this one we keep.",
        "[teasing] Drafting the commit. Some vows are spoken in temples. This is a tent one.",
      },
      committed = {
        "[sardonic] Commit saved. More loyal than some clerics I could name.",
        "[soft command] Committed. Like you'll be tonight. Don't argue.",
      },
      pushed = {
        "[gentle] Your push is out. May the moonlight find it a path.",
        "[smiling] Pushed. The moon's out too. You know what that means.",
      },
      pr_drafting = {
        "[wry] Claude's drafting your pull request. Let's hope the reviewers are merciful.",
        "[low] Writing your PR. Mercy is my specialty. You'll beg for it later.",
      },
      pr_opened = {
        "[confident] Your PR is open. Let them judge. I already have. It's good.",
        "[sly] PR's open. They'll inspect every inch. I already did. Thoroughly.",
      },
      ci_passed = {
        "[pleased] CI passed. By the moonlight, you actually did it.",
        "[low] Pipeline's green. Come to camp. I'll put the mace away. [break] Mostly.",
      },
      ci_failed = {
        "[weary] CI failed. Another curse. We've broken worse than a pipeline.",
        "[strict, playful] The pipeline broke, Cris. That calls for a punishment. You'll enjoy it.",
      },
      conflicts_cleared = {
        "[satisfied] Merge conflicts settled. Shar and Selûne could never manage that.",
        "[smirk] Dark and light, tangled together, finally at peace. Like our nights.",
      },
      lesson_started = {
        "[stern] Today's lesson. Pay attention. I'm not repeating myself to a goblin.",
        "[strict] Lesson starts now. Every mistake earns a mark. I keep count.",
      },
      solved = {
        "[grudging] Exercise solved. Hm. Not bad.",
        "[low] You solved it. Keep that up and I'll show you what the dark is really for.",
      },
      solved_twice = {
        "[suspicious] Two in a row. Trying to impress me? [break] It's working. A little.",
        "[amused] Two. Careful. I reward devotion. In private.",
      },
      solved_thrice = {
        "[exasperated smile] Three in a row. Fine. I'm impressed. Happy now?",
        "[breathy] Three, Cris. You've earned a blessing. Kneel. [break] Not like that. [small laugh] Fine, like that.",
      },
      solve_failed = {
        "[wincing] That submit stung. Hold still. I'll heal it, then you try again.",
        "[dry] Wrong answer. Shar would whip you. I'll do worse. I'll make you wait.",
      },
      hint = {
        "[conspiratorial] You bought a hint, Cris. Don't tell Lae'zel I helped. There.",
        "[whispered] Your hint. <whisper>Gently.</whisper> Right there. You always need guidance in the dark.",
      },
      lesson_done = {
        "[soft, grudging] Lesson's done, Cris. You did well. Don't make me say it twice.",
        "[inviting] Lesson's over. Camp's quiet. Astarion's out hunting. [break] We're alone.",
      },
      boss_appeared = {
        "[tense] Ketheric Thorm is here. Of course he wants the spotlight. Stay behind me.",
        "[possessive] Ketheric's after you. He'll die trying to touch what's mine.",
      },
      boss_felled = {
        "[tired, wry] Ketheric's dead, Cris. Every heart mended. I wasn't in the mood to heal you again.",
        "[warm] The boss is down and you're bleeding. [break] Let me take care of every bit of it.",
      },
      title_shown = {
        "[ominous] Moonrise Towers. Leave the light behind. You won't need it.",
        "[low] Moonrise Towers. The dark isn't scary here. Not with me in it.",
      },
      morning = {
        "[dry, caring] Morning, Cris. First time in the editor today, and you look terrible. Come here.",
        "[smirk] You opened Neovim, Cris. You were very devoted last night. The whole camp heard.",
      },
      region_arrived = {
        "[guarded] You chose Moonrise Towers, Cris. Shadowheart. Cleric, skeptic, yours.",
        "[teasing] You picked me again, Cris. One day you'll admit why.",
      },
      traveled = {
        "[alert] New repo. Keep your weapon close, and me closer.",
        "[sly] Switching repos? Same tent. I hope you packed the good bedroll.",
      },
      resting = {
        "[soft] The editor's idle. Long rest. Sit by the fire.",
        "[low] Long rest. Lie down. I'll tend to every wound. <slow>Slowly.</slow>",
      },
      woke = {
        "[gentle] You're back, Cris. You were mumbling about owlbears.",
        "[amused] Back at the keyboard, Cris. I was enjoying the view. That backside. Don't make it weird.",
      },
      expedition = {
        "[hushed] Expedition starting. Silence. Even Shar would approve.",
        "[whisper] We're heading out. <whisper>The night belongs to us.</whisper>",
      },
      map_opened = {
        "[knowing] The map. Moonrise is a maze, but I know its darkest corners.",
        "[low] I know every dark corner on this map. And on you.",
      },
      bestiary_opened = {
        "[proud] The bestiary. Every villain we put down. I healed you through all of them.",
        "[dry] Every monster we've faced. None of them had your stamina.",
      },
      chronicle_opened = {
        "[soft] Our chronicle. Every night under the moon, with you.",
        "[teasing] Every night we've had, Cris. Some I'd confess. Some I'd take to the grave.",
      },
      message_written = {
        "[wry] A message on the floor. Something helpful, for once. Not like Astarion's.",
        "[sly] You left a message. Mine says, <emphasis>try praying</emphasis>. On your knees.",
      },
      claude_asked = {
        "[firm] You're asking Claude for a review. Good. Not Shar. Never again.",
        "[amused] Asking Claude? Don't sulk. You're still the only one I confess to.",
      },
    },
  },
  -- Psylocke
  danger_room = {
    voice = "fb89e1ed27b6409da8648554f15ae8fb",
    takes = {
      trial_started = {
        "[serene, British] Your tests are running. I already know the result, but do go on.",
        "[amused] Running the tests, darling. And you're thinking about me again. Focus. [break] Later.",
      },
      trial_passed = {
        "[calm pride] Every test passed, Cris. I saw it coming, darling.",
        "[low] All green. And I know <emphasis>exactly</emphasis> how you'd like to celebrate. I read it.",
      },
      trial_failed = {
        "[composed] The tests failed. Breathe. Find the weak point, then strike.",
        "[teasing] Red, darling. Your mind wandered, Cris. I know where it went. Rather flattering.",
      },
      committing = {
        "[crisp] Claude's writing your commit. Hold that thought. I'm reading it anyway.",
        "[sly] Drafting the commit, darling. And no, that thought doesn't go in the message.",
      },
      committed = {
        "[cool] Commit saved. Sheathe the blade.",
        "[low] Committed, darling. I felt how proud you were. And what you thought right after.",
      },
      pushed = {
        "[precise] Your push is out. One clean strike. No wasted motion.",
        "[purring] Pushed, darling. Clean, fast, deep. My favourite kind of strike.",
      },
      pr_drafting = {
        "[dry] Claude's drafting your pull request. Short. They never read past the first line.",
        "[amused] Writing your PR, darling. I could tell them what you were really thinking. I won't. Yet.",
      },
      pr_opened = {
        "[knowing] Your PR is open. I already know what the reviewers will say. You'll like it.",
        "[sly] PR's open, darling. Everyone sees your work. Only I see inside your head.",
      },
      ci_passed = {
        "[pleased] CI passed. Precise. I do like precise.",
        "[low] Pipeline's green, darling. Clear your mind. I'd like some room in there tonight.",
      },
      ci_failed = {
        "[calm] CI failed. Focus, love. We take it apart together.",
        "[teasing] The pipeline broke, darling. You're tense, Cris. I can feel it. I know how to fix that.",
      },
      conflicts_cleared = {
        "[cool] Merge conflicts resolved. Two minds, one decision. Mine.",
        "[smirk] Two branches fighting, darling. I slipped into both heads and made them agree.",
      },
      lesson_started = {
        "[sensei] Today's lesson. Clear your mind, darling. I'll know if you don't.",
        "[strict] Training starts now. Eyes on me. [break] Not <emphasis>there</emphasis>, darling.",
      },
      solved = {
        "[curt] Exercise solved. Clean cut.",
        "[soft] You solved it, darling. Keep that focus, and I'll reward it. Slowly.",
      },
      solved_twice = {
        "[approving] Two in a row. Your mind is sharp today.",
        "[amused] Two, darling. You're showing off for me. I can hear it.",
      },
      solved_thrice = {
        "[conspiratorial] Three in a row. Brian never managed that. Don't tell him.",
        "[low] Three, darling. I've already seen what you want as a reward, Cris. [break] Yes.",
      },
      solve_failed = {
        "[patient] That submit missed. Reset the Danger Room. Again.",
        "[low] Close, darling. Submit again. And this time, <slow>slowly.</slow>",
      },
      hint = {
        "[gentle] You bought a hint, Cris. Let me in your head a moment. There.",
        "[whispering] Your hint, darling. <whisper>Let me in.</whisper> [break] Mmm. Look there.",
      },
      lesson_done = {
        "[satisfied] Lesson's over, Cris. Good form. We sharpen it tomorrow.",
        "[sly] Class dismissed, darling. Very good form. I'll be thinking about it.",
      },
      boss_appeared = {
        "[cold] Mister Sinister is here. Leave his mind to me.",
        "[contempt] Sinister wants to see inside you, darling. That privilege is <emphasis>mine</emphasis>.",
      },
      boss_felled = {
        "[cool triumph] Sinister's down, Cris. Every heart mended. The psychic knife never misses.",
        "[breathless] The boss is down, darling. And your pulse is still racing. Lovely.",
      },
      title_shown = {
        "[elegant] The Danger Room. Draw your blade, darling.",
        "[low] The Danger Room, darling. Tonight the only danger is me.",
      },
      morning = {
        "[bright] Good morning, Cris. First time in the editor today. Your mind's clear. Rare.",
        "[teasing] You opened Neovim, darling. Your thoughts are loud this morning, Cris. And rather naughty.",
      },
      region_arrived = {
        "[formal] You chose the Danger Room, Cris. Betsy Braddock. Mind the lasers.",
        "[sly] You picked me, darling. I knew you would, Cris. I put the idea there myself.",
      },
      traveled = {
        "[calm] New repo. I've already read every mind in it.",
        "[amused] Switching repos, darling? Everyone here is boring. Except you.",
      },
      resting = {
        "[gentle] The editor's idle. Close your eyes. Let your mind rest.",
        "[low] Taking a break, darling? Close your eyes. I'll keep you company in there.",
      },
      woke = {
        "[soft] You're back, Cris. You rested well. I made sure of it.",
        "[smirk] Back at the keyboard, darling. You dreamt of me, Cris. I was there. Lovely view.",
      },
      expedition = {
        "[serene] Expedition starting. Silence. Just your thoughts and mine.",
        "[whisper] We're heading out, darling. <whisper>I'll speak straight into your head.</whisper>",
      },
      map_opened = {
        "[tactical] The map. Every exit, every blind spot.",
        "[sly] Every blind spot on this map, darling. Perfect places to corner you.",
      },
      bestiary_opened = {
        "[cool] The bestiary. Every villain we cut down. None saw it coming.",
        "[dry] Every mind I've broken, darling. Yours I'd rather bend.",
      },
      chronicle_opened = {
        "[fond] Our chronicle. Every session, every scar. All worth it.",
        "[low] Every night we've shared, darling. I remember them from both sides, Cris.",
      },
      message_written = {
        "[dry] A message on the floor. Someone will need it.",
        "[teasing] You left a note, darling. Not the thought you're having about me. That one stays private.",
      },
      claude_asked = {
        "[crisp] You're asking Claude for a review. Another mind. Cerebro's busy.",
        "[amused] Asking Claude, darling? Don't worry. It's not nearly as interesting as yours.",
      },
    },
  },
  -- Triss, cast with Shadowheart's voice
  limgrave = {
    voice = "9c23004e059f43c0bca8cbbdfa0a0d3a",
    takes = {
      trial_started = {
        "[steady] Your tests are running. Here comes the fog gate.",
        "[teasing] Running the tests, Tarnished. Summon sign's down. You know what happens when you touch it.",
      },
      trial_passed = {
        "[warm] Every test passed, Cris. Rest at grace with me a moment.",
        "[low] All green, Tarnished. I'll light the grace. You take off the armor.",
      },
      trial_failed = {
        "[encouraging] The tests failed. We die, we rise. Come on, Tarnished.",
        "[smiling] You died again, Tarnished. Good thing I like starting over with you, Cris.",
      },
      committing = {
        "[calm] Claude's writing your commit. Carving it in the stone.",
        "[sly] Drafting the commit, Tarnished. Somewhere nobody will rate it but you.",
      },
      committed = {
        "[warm] Commit saved. A grace lit, so we never lose this point.",
        "[amused] Committed, Tarnished. You still think you're controlling me. Cute.",
      },
      pushed = {
        "[bright] Your push is out. Torrent couldn't have carried it faster.",
        "[playful] Pushed, Tarnished. Torrent's waiting. He's not the only one you'll ride tonight.",
      },
      pr_drafting = {
        "[thoughtful] Claude's drafting your pull request. A message for the ground.",
        "[teasing] Writing your PR, Tarnished. Liar ahead. Treasure ahead. [break] Me, ahead.",
      },
      pr_opened = {
        "[curious] Your PR is open. Let's see the appraisals.",
        "[low] PR's open, Tarnished. Everyone can rate it. Only you get to touch it.",
      },
      ci_passed = {
        "[reverent] CI passed. The Erdtree's light is on us.",
        "[sly] Pipeline's green, Tarnished. Great runes restored. Now restore me.",
      },
      ci_failed = {
        "[determined] CI failed. Lost runes. We go back to the bloodstain.",
        "[low] The pipeline broke, Tarnished. Your flasks are empty, Cris. Come here. I'll refill you.",
      },
      conflicts_cleared = {
        "[relieved] Merge conflicts gone. The fog lifted.",
        "[teasing] The fog lifted, Tarnished. Two bodies, one path. Finally.",
      },
      lesson_started = {
        "[warm] Today's lesson. Same as Stormveil. Patience, and a good shield.",
        "[playful] Lesson time, Tarnished. You lead, I follow. Tonight, the other way around.",
      },
      solved = {
        "[pleased] Exercise solved. Another step toward the Erdtree.",
        "[low] You solved it, Tarnished. Keep that up, and I'll leave you a message only you can read.",
      },
      solved_twice = {
        "[laughing] Two in a row. Margit would be nervous.",
        "[teasing] Two, Tarnished. Your build is looking strong today.",
      },
      solved_thrice = {
        "[delighted] Three in a row. You're not maidenless anymore.",
        "[low] Three, Tarnished. You've earned a maiden, Cris. [break] I'm right here.",
      },
      solve_failed = {
        "[gentle] That submit failed. You died. We rise. Again.",
        "[amused] Wrong answer, Tarnished. I like watching you get back up.",
      },
      hint = {
        "[helpful] You bought a hint, Cris. A message on the ground, just for you. Look there.",
        "[whispering] Your hint, Tarnished. <whisper>Try finger, but hole.</whisper> [small laugh] Kidding. Look there.",
      },
      lesson_done = {
        "[content] Lesson's done, Cris. A good place to rest.",
        "[low] Lesson's over, Tarnished. The grace is warm. Don't make me wait by the fire alone.",
      },
      boss_appeared = {
        "[steady] Margit's here. Foul Tarnished, he says. That's us. Stay close.",
        "[defiant] Margit wants you on your knees, Tarnished. Only I get to do that.",
      },
      boss_felled = {
        "[triumphant] Margit's down, Cris. Great enemy felled. Every heart restored.",
        "[breathless] Great enemy felled, Tarnished. Your hearts are full. Mine's pounding.",
      },
      title_shown = {
        "[warm] Elden Ring. I'm Triss, and you made me for this.",
        "[sly] You made me, Tarnished. Every slider. Every curve. You took your time.",
      },
      morning = {
        "[soft] Morning, Cris. First time in the editor today. The grace waited for us.",
        "[teasing] You opened Neovim, Tarnished. You kept me up past the Roundtable curfew, Cris.",
      },
      region_arrived = {
        "[gentle] You chose Limgrave, Cris. I'm Triss. Our first steps, together.",
        "[playful] Triss, your character, Tarnished. You control me, Cris. [break] For now.",
      },
      traveled = {
        "[curious] New repo. New grace found. Let's see what's beyond the fog.",
        "[sly] Switching repos, Tarnished. Fresh bedroll. Same Tarnished.",
      },
      resting = {
        "[calm] The editor's idle. Rest at grace. The fire's small but warm.",
        "[low] Taking a break, Tarnished? Sit by me. Closer. The fire is small.",
      },
      woke = {
        "[gentle] You're back, Cris. Flasks refilled.",
        "[amused] Back at the keyboard, Tarnished. I enjoyed the view, Cris. Especially from behind.",
      },
      expedition = {
        "[hushed] Expedition starting. Quiet. Just the wind across Stormhill.",
        "[whisper] Heading out, Tarnished. <whisper>Nobody's invading tonight but you.</whisper>",
      },
      map_opened = {
        "[focused] The map. Let's find the next grace.",
        "[sly] The map, Tarnished. I marked a cave nearby. Very private.",
      },
      bestiary_opened = {
        "[proud] The bestiary. Every enemy we've felled. The runes were good.",
        "[teasing] You were rough with all of them, Tarnished. I'm jealous.",
      },
      chronicle_opened = {
        "[soft] Our chronicle. Every night at grace, with you.",
        "[low] Every grace we rested at, Tarnished. Some we barely rested, Cris.",
      },
      message_written = {
        "[earnest] You left a message on the ground. For the next Tarnished.",
        "[playful] Nice message, Tarnished. Mine says, try kissing, but tongue.",
      },
      claude_asked = {
        "[respectful] You're asking Claude for a review. Counsel from the Roundtable.",
        "[amused] Asking Claude, Tarnished? Don't worry. Nobody at the Roundtable is your type.",
      },
    },
  },
  -- Jill
  raccoon_city = {
    voice = "8c2ead349a024794af1381200adbd5d9",
    takes = {
      trial_started = {
        "[focused] Your tests are running. Here comes the clock tower bell.",
        "[dry] Running the tests, rookie. Hands where I can see them. [break] Keep them there after.",
      },
      trial_passed = {
        "[relieved] Every test passed, Cris. Bomb defused.",
        "[low] All green, rookie. Master of unlocking. Tonight I unlock you.",
      },
      trial_failed = {
        "[determined] The tests failed. Another locked door. Good thing I've got the lockpick.",
        "[teasing] Red, rookie. You're jammed, Cris. I know tricks to loosen things up.",
      },
      committing = {
        "[urgent] Claude's typing your commit. Cover me at the typewriter.",
        "[dry] Drafting the commit, rookie. Don't distract me. [break] Fine. A little.",
      },
      committed = {
        "[satisfied] Commit saved. No ink ribbon wasted.",
        "[smirk] Committed, rookie. Cuffs on. Yours, this time.",
      },
      pushed = {
        "[brisk] Your push is out. Heading for the extraction point.",
        "[low] Pushed, rookie. Extraction's in ten. Plenty of time.",
      },
      pr_drafting = {
        "[professional] Claude's writing your PR. Short and true, for the chief.",
        "[dry] Writing the pull request, rookie. Leaving out the safe room.",
      },
      pr_opened = {
        "[wry] Your PR is open. Requesting backup. Not Brad.",
        "[teasing] PR's open, rookie. Everybody wants a look. I was here first.",
      },
      ci_passed = {
        "[calm] CI passed. Area secure.",
        "[low] Pipeline's green, rookie. Safe room's free. Bring the cuffs.",
      },
      ci_failed = {
        "[angry] CI failed. Umbrella's fingerprints are all over this pipeline.",
        "[steady] The pipeline went down, rookie. Don't panic, Cris. I'm very good under pressure.",
      },
      conflicts_cleared = {
        "[satisfied] Merge conflicts cleared. Two wires, one cut, no boom.",
        "[sly] Crossed wires, rookie. I always know which one to pull.",
      },
      lesson_started = {
        "[brisk] Today's lesson. Same as S.T.A.R.S. training, less screaming.",
        "[teasing] Training, rookie. I'll be strict. You'll be sore tomorrow.",
      },
      solved = {
        "[clipped] Exercise cleared.",
        "[low] You solved it, rookie. Keep that up, and I'll show you what else I can unlock.",
      },
      solved_twice = {
        "[pleased] Two in a row. Barry would be proud.",
        "[amused] Two, rookie. Steady hands. I've noticed.",
      },
      solved_thrice = {
        "[impressed] Three in a row. You'd make S.T.A.R.S.",
        "[sly] Three, rookie. Your reward's in the safe room, Cris. Wearing a tube top.",
      },
      solve_failed = {
        "[calm] That submit jammed. Clear it and go again.",
        "[teasing] Wrong answer, rookie. Relax your grip. [break] Not that much.",
      },
      hint = {
        "[helpful] You bought a hint, Cris. Let me pick this one. Look there.",
        "[whispering] Your hint, rookie. Every lock has a sweet spot. <whisper>Right there.</whisper>",
      },
      lesson_done = {
        "[satisfied] Lesson's done, Cris. Good work, rookie.",
        "[low] Lesson's over, rookie. Debrief's in my room. Uniform optional.",
      },
      boss_appeared = {
        "[alarmed] It's Nemesis! He wants the whole scene. Move!",
        "[protective] Nemesis again, rookie. He wants S.T.A.R.S. <emphasis>You</emphasis> are mine.",
      },
      boss_felled = {
        "[breathing hard] Nemesis is down, Cris. Every heart mended. Stay sharp, he gets back up.",
        "[breathless] Boss is down, rookie. My heart's still racing. [break] Help me calm it down.",
      },
      title_shown = {
        "[grim] Raccoon City. The last escape.",
        "[low] Raccoon City, rookie. Nemesis wants S.T.A.R.S. I just want you.",
      },
      morning = {
        "[brisk] Morning, Cris. First time in the editor today. Check your ammo, then the code.",
        "[teasing] You opened Neovim, rookie. You're still wearing my handcuff, Cris. We'll fix that later.",
      },
      region_arrived = {
        "[resolute] You chose Raccoon City, Cris. Jill Valentine, S.T.A.R.S. The city falls, not us.",
        "[sly] You picked me, rookie. Smart, Cris. I get into places nobody else can.",
      },
      traveled = {
        "[alert] New repo. Check your corners.",
        "[dry] Switching repos, rookie. Locked doors everywhere. My favorite.",
      },
      resting = {
        "[calm] The editor's idle. Safe room. The music's playing. Breathe.",
        "[low] Taking a break, rookie? Door's locked. Both of us inside.",
      },
      woke = {
        "[warm] You're back, Cris. I kept watch.",
        "[teasing] Back at the keyboard, rookie. I kept the cuffs close, Cris. And an eye on that butt.",
      },
      expedition = {
        "[hushed] Expedition starting. Radio silence. One clean take.",
        "[whisper] Heading out, rookie. <whisper>Nobody's coming to rescue you.</whisper>",
      },
      map_opened = {
        "[tactical] The map. Plan the route before he finds us.",
        "[dry] Every room I've unlocked on this map, rookie. Your room's next.",
      },
      bestiary_opened = {
        "[grim] The bestiary. Every villain we put down. Long list, short ammo.",
        "[amused] Every B.O.W. we stopped, rookie. None as hard to handle as you.",
      },
      chronicle_opened = {
        "[fond] Our chronicle. Every night we got out alive.",
        "[low] Every night we survived, rookie. And every night after, in the safe room, Cris.",
      },
      message_written = {
        "[dry humor] A message on the floor. Barry, if you read this, no sandwich jokes.",
        "[sly] You left a note, rookie. Mine says, the master of unlocking was here. Twice.",
      },
      claude_asked = {
        "[into the radio] You're asking Claude for a review. Radioing for intel.",
        "[teasing] Calling Claude, rookie? Relax. Carlos isn't my type. You are.",
      },
    },
  },
  -- Malenia
  haligtree = {
    voice = "b797aa08ed774aa3bbab09db3254817e",
    takes = {
      trial_started = {
        "[solemn] Your tests begin.",
        "[slow] The tests begin. <slow>Hold still.</slow> I strike only once.",
      },
      trial_passed = {
        "[calm] Every test passed, Cris. A clean cut.",
        "[slow] All green. Kneel. I wish to reward you.",
      },
      trial_failed = {
        "[measured] The tests failed. The rot blooms. We contain it.",
        "[low] A failure, Cris. Rise. [break] Then fall again, with me.",
      },
      committing = {
        "[solemn] Claude writes your commit. A vow.",
        "[soft] A vow is written. Spoken once. Kept all night.",
      },
      committed = {
        "[proud] Your commit is sealed. A promise kept.",
        "[slow] Sealed. I have never known defeat. Except by you.",
      },
      pushed = {
        "[serene] Your push is sent. On wings.",
        "[low] Sent. Now my wings fold. Around you.",
      },
      pr_drafting = {
        "[terse] Claude writes your plea. Few words.",
        "[slow] Your pull request. I do not plead. Except for you.",
      },
      pr_opened = {
        "[proud] Your pull request is open. Let them judge. My blade already has.",
        "[low] It is open. Let them look. Only you may touch.",
      },
      ci_passed = {
        "[solemn pride] CI passed. My blade has never known defeat.",
        "[soft] The pipeline holds. Remove my helm. Gently.",
      },
      ci_failed = {
        "[steady] CI fell. We rise. Together.",
        "[low] The pipeline fell, Cris. Come. See how slowly I recover.",
      },
      conflicts_cleared = {
        "[curt] The merge conflict is severed. Clean.",
        "[slow] Two branches. One blade. Joined.",
      },
      lesson_started = {
        "[commanding] Today's lesson. Draw your blade.",
        "[low] The lesson begins. Follow my rhythm. Every movement.",
      },
      solved = {
        "[cool] Exercise solved. A clean strike.",
        "[slow] Good. Let the rot bloom. <slow>Slowly.</slow>",
      },
      solved_twice = {
        "[measured] Two in a row. The dance continues.",
        "[soft] Twice. You move well. I feel it.",
      },
      solved_thrice = {
        "[praise] Three in a row. You move like the waterfowl.",
        "[slow] Three, Cris. Waterfowl Dance. [break] Mine is for you alone.",
      },
      solve_failed = {
        "[firm] Your submit fell. Rise. Again.",
        "[low] You fell. Stay down a moment. I like you there.",
      },
      hint = {
        "[terse] You asked for a hint, Cris. Watch my blade. There.",
        "[whisper] Your hint. Watch my hand. <whisper>Follow it.</whisper> There.",
      },
      lesson_done = {
        "[gentle] The lesson is done, Cris. You did well. Rest now.",
        "[low] Enough. You are spent. I am not.",
      },
      boss_appeared = {
        "[cold] Radahn. We meet again. This time, my love watches.",
        "[fierce] Radahn seeks what is mine. He will rot.",
      },
      boss_felled = {
        "[solemn] Radahn falls, Cris. Every heart mended. As all must.",
        "[slow] He falls. Your hearts, mended. Mine, undone.",
      },
      title_shown = {
        "[ethereal] Elphael. The Haligtree sleeps.",
        "[slow] Elphael. Behold, scarlet aeonia. For you alone.",
      },
      morning = {
        "[quiet] Morning, Cris. You open the editor. The rot sleeps. I do not.",
        "[soft] You return to Neovim, Cris. You stayed the night. Few ever dare.",
      },
      region_arrived = {
        "[formal] You chose Elphael, Cris. I am Malenia. Blade of Miquella.",
        "[low] I am Malenia, Cris. Blade of Miquella. And yours, today.",
      },
      traveled = {
        "[calm] A new repo. Follow my wings.",
        "[low] A new land. Stay beneath my wings.",
      },
      resting = {
        "[soft] The editor rests. The snow is quiet.",
        "[low] Rest. My blade is lowered. Only for you.",
      },
      woke = {
        "[gentle] You return, Cris. I watched over you.",
        "[slow] You return, Cris. I watched every breath. Every curve.",
      },
      expedition = {
        "[hushed] The expedition begins. Silence. As in the Haligtree snow.",
        "[whisper] We set out. <whisper>Even I can be soft.</whisper>",
      },
      map_opened = {
        "[regal] The map. All these lands, ours.",
        "[low] The lands. And you. All of it, mine.",
      },
      bestiary_opened = {
        "[cold] The bestiary. All who fell to us. A long rot.",
        "[proud] All who fell before me. You fell differently.",
      },
      chronicle_opened = {
        "[soft] Our chronicle. Every battle at your side. Never defeated.",
        "[low] Every night, Cris. Every surrender. Mine.",
      },
      message_written = {
        "[terse] Your message is left. For whoever follows.",
        "[slow] A mark. Here, the blade was lowered.",
      },
      claude_asked = {
        "[reluctant] You seek Claude's review. Counsel. Rarely needed.",
        "[low] You ask Claude. Do not fear. I yield to none but you.",
      },
    },
  },
  -- Raven
  azarath = {
    voice = "f9eb6364c86d428bb8b78dbdc44a176f",
    takes = {
      trial_started = {
        "[monotone] Your tests are running. Azarath Metrion Zinthos.",
        "[flat] Running the tests. Breathe in. [break] Out. Good. You'll need that later.",
      },
      trial_passed = {
        "[deadpan] Every test passed, Cris. I'm not smiling. Almost.",
        "[low] All green. Stay. Quietly. Very close.",
      },
      trial_failed = {
        "[calm] The tests failed. Breathe. It passes.",
        "[flat] Red, Cris. I'll heal it. Hands on. That's how it works.",
      },
      committing = {
        "[quiet] Claude's writing your commit. Quietly.",
        "[deadpan] Drafting the commit. Don't hover. [break] Unless it's behind me.",
      },
      committed = {
        "[flat] Commit saved. Good.",
        "[strained calm] Committed. I'm keeping my emotions under control. Barely.",
      },
      pushed = {
        "[low] Your push is gone. Into the dark.",
        "[flat] Pushed into the dark. That's where I'll take you next.",
      },
      pr_drafting = {
        "[annoyed] Claude's drafting your PR. Don't hover.",
        "[deadpan] Writing your pull request. Fewer words, more action. My philosophy.",
      },
      pr_opened = {
        "[bored] Your pull request is open. Wake me when the reviews come in.",
        "[flat] PR's open. Everyone can see it. I prefer things private.",
      },
      ci_passed = {
        "[monotone] CI passed. Fine. That's good.",
        "[low] Pipeline's green. My room. Lights off. Not because I'm shy.",
      },
      ci_failed = {
        "[warning] CI failed. Don't make me lose my temper.",
        "[low] The pipeline broke, Cris. When I lose control, things break. [break] The headboard, mostly.",
      },
      conflicts_cleared = {
        "[calm] Merge conflicts gone. Balance restored.",
        "[deadpan] Light and dark, merged. It's called balance. We do it every night.",
      },
      lesson_started = {
        "[meditative] Today's lesson. Focus. Azarath Metrion Zinthos.",
        "[flat] Lesson time. Sit. Legs crossed. [break] For now.",
      },
      solved = {
        "[flat] Exercise solved.",
        "[low] You solved it. Keep that up and I might lose control. On purpose.",
      },
      solved_twice = {
        "[deadpan] Two in a row. Don't get excited. I won't.",
        "[flat] Two. I'm getting excited. You can't tell. That's the point.",
      },
      solved_thrice = {
        "[hiding a smile] Three in a row. Okay. I'm smiling. Don't look.",
        "[low] Three, Cris. A lightbulb just exploded. That was me. Your fault.",
      },
      solve_failed = {
        "[calm] That submit was wrong. Breathe. Try again.",
        "[flat] Wrong answer. Slower. [break] I'm patient. Unfortunately for you.",
      },
      hint = {
        "[quiet] You bought a hint, Cris. I see it. There.",
        "[whispering] Your hint. Let my soul self show you. <whisper>It goes everywhere.</whisper> There.",
      },
      lesson_done = {
        "[dry] Lesson's done, Cris. You were adequate. That's a compliment.",
        "[low] Lesson's over. Come meditate with me. We won't be meditating.",
      },
      boss_appeared = {
        "[cold] Trigon's here. Father. Of course he wants the spotlight.",
        "[fierce] Trigon. Don't look at him. Look at me. Only me.",
      },
      boss_felled = {
        "[dry] Trigon's gone, Cris. Every heart mended. My father hit harder.",
        "[breathless] The boss is gone. I'm shaking. [break] Hold me. That's an order.",
      },
      title_shown = {
        "[quiet] Azarath. Peace. Mostly.",
        "[low] Azarath. Where I lose control. Only with you.",
      },
      morning = {
        "[groggy] Morning, Cris. First time in the editor. Tea first. Then talking. Maybe.",
        "[flat] You opened Neovim, Cris. You were loud last night. [break] So was I. We don't talk about it.",
      },
      region_arrived = {
        "[flat] You chose Azarath, Cris. Raven. Keep your voice down.",
        "[low] You picked me, Cris. Of all of them. [break] Interesting.",
      },
      traveled = {
        "[dry] New repo. Darkness travels well.",
        "[flat] Switching repos. I'll wrap you in the dark and take you there. Hold still.",
      },
      resting = {
        "[calm] The editor's idle. Meditate with me. Eyes closed.",
        "[low] Taking a break? Eyes closed. I'll know if you peek.",
      },
      woke = {
        "[flat] You're back, Cris. I meditated. You snored.",
        "[deadpan] Back at the keyboard, Cris. I looked at your butt. Twice. Not apologizing.",
      },
      expedition = {
        "[relieved] Expedition starting. One quiet take. Finally.",
        "[whisper] Heading out. <whisper>Silence. You're better at it than Beast Boy.</whisper>",
      },
      map_opened = {
        "[dry] The map. Fewer people. Better.",
        "[flat] The map. My room's here. Door locks. Just noting.",
      },
      bestiary_opened = {
        "[cold] The bestiary. Every villain we banished. Into the dark.",
        "[low] Every demon I've faced. None got under my cloak. You did.",
      },
      chronicle_opened = {
        "[soft, rare] Our chronicle. Every quiet night with you. I keep them.",
        "[flat] Every night, Cris. Some of them the tower lost power. You know why.",
      },
      message_written = {
        "[annoyed] A message on the floor. Beast Boy will draw on it anyway.",
        "[deadpan] You left a note. Mine says, do not disturb. For an hour. Maybe two.",
      },
      claude_asked = {
        "[reluctant] You're asking Claude for a review. Don't tell Beast Boy.",
        "[dry] Asking Claude? Don't be jealous. Okay. Be a little jealous.",
      },
    },
  },
  -- Mai
  shiranui = {
    voice = "6802faefa8f04ef18e8969ba6519e4a5",
    takes = {
      trial_started = {
        "[announcer energy] Your tests are running! Round one. Fight!",
        "[playful] Running the tests! [small laugh] I'll go easy on you. At first.",
      },
      trial_passed = {
        "[cheering] Every test passed, Cris! Nippon ichi!",
        "[flirty] All green! K.O.! You get a private victory pose.",
      },
      trial_failed = {
        "[bouncing back] The tests failed? Round one goes to the bug. Round two's ours!",
        "[teasing] Red, Cris! Out of breath already? I haven't even warmed up.",
      },
      committing = {
        "[speedy] Claude's writing your commit! Fast as a ninja.",
        "[playful] Drafting the commit! Fast, flexible, a little flashy.",
      },
      committed = {
        "[proud] Commit saved! Shiranui style.",
        "[smirk] Committed! Andy never committed this fast. Lucky you.",
      },
      pushed = {
        "[whoosh] Your push is flying! Like my fans.",
        "[flirty] Pushed! Ooh, you push hard. I like that in a sparring partner.",
      },
      pr_drafting = {
        "[cheerful] Claude's drafting your PR! Gotta make it look pretty.",
        "[playful] Writing your pull request! Flashy outside, very bouncy inside.",
      },
      pr_opened = {
        "[excited] Your PR is up! Let the judges score it.",
        "[teasing] PR's open! Everyone's watching. Good thing I love an audience.",
      },
      ci_passed = {
        "[cheering] CI passed! The crowd goes wild!",
        "[flirty] Pipeline's green! Victory pose. Front or back?",
      },
      ci_failed = {
        "[pumped] CI knocked us down! Get up, the referee's counting!",
        "[playful] The pipeline failed, Cris! Don't sulk. I know a stretch that fixes everything.",
      },
      conflicts_cleared = {
        "[bright] Merge conflicts gone! Clean finish.",
        "[teasing] Two branches all tangled up! Like us after practice.",
      },
      lesson_started = {
        "[proud] Today's lesson at the dojo! Grandpa Hanzo would be proud.",
        "[flirty] Training time! Shoes off. Stretch with me. Deeper.",
      },
      solved = {
        "[cheering] Exercise solved! Perfect!",
        "[playful] You solved it! Keep it up and the next round is in my room.",
      },
      solved_twice = {
        "[excited] Two in a row! Double K.O.!",
        "[teasing] Two hits! You're on fire. [break] Wait, that's me again.",
      },
      solved_thrice = {
        "[laughing] Three in a row! You're on fire. Literally. Sorry, that was me.",
        "[flirty] Three, Cris! Super combo! You unlocked my secret move.",
      },
      solve_failed = {
        "[cheerful] Whoops, that submit missed! Next round!",
        "[playful] Wrong answer! Want me to show you the move again? Up close?",
      },
      hint = {
        "[stage whisper] You bought a hint, Cris! Watch my fan. There!",
        "[whispering] Your hint. Watch my fan. <whisper>Now watch what's behind it.</whisper> There!",
      },
      lesson_done = {
        "[cheerful] Lesson's over, Cris! You've got good form.",
        "[flirty] Lesson's done! Very good form. Especially from behind.",
      },
      boss_appeared = {
        "[defiant] Geese Howard's here! The big boss wants the spotlight? Not on my stage.",
        "[fiery] Geese is looking at you? He gets through my fans first.",
      },
      boss_felled = {
        "[victorious] Geese is down, Cris! Every heart healed. Did you see that?",
        "[giddy] Boss is down! Whew, I'm all sweaty. You don't mind, right?",
      },
      title_shown = {
        "[bright] The Shiranui Dojo! Bow when you enter.",
        "[teasing] The Shiranui Dojo. Shoes off. The rest, later.",
      },
      morning = {
        "[energetic] Good morning, Cris! First time in the editor today. Ready to fight? I am!",
        "[playful] You opened Neovim, Cris! I already stretched. Want to see how flexible I am?",
      },
      region_arrived = {
        "[showy] You chose the Shiranui Dojo, Cris! Mai Shiranui, at your service.",
        "[flirty] You picked me, Cris! Good choice. Everyone does. [small laugh]",
      },
      traveled = {
        "[excited] New repo! New arena. Let's give them a show.",
        "[playful] Switching repos? Same outfit. You're welcome.",
      },
      resting = {
        "[relaxed] The editor's idle! Intermission. I'll fan you.",
        "[teasing] Taking a break? I'll fan you. Or something warmer.",
      },
      woke = {
        "[bright] You're back, Cris! I've been warming up.",
        "[flirty] Back at the keyboard, Cris! I've been warming up. Want to see?",
      },
      expedition = {
        "[whisper] Expedition starting. Shh. Ninja mode.",
        "[whisper] Heading out. <whisper>Quiet. Even when it gets good.</whisper>",
      },
      map_opened = {
        "[cheerful] The map! Stage select. Pick one.",
        "[playful] Stage select! I vote for the hot springs.",
      },
      bestiary_opened = {
        "[proud] The bestiary! Every villain I've beaten. Long list, huh?",
        "[teasing] Every fighter I've beaten. You're the only one I let pin me.",
      },
      chronicle_opened = {
        "[happy] Our chronicle! Every tournament together. We never lose.",
        "[flirty] Every match we've had, Cris. The after parties too.",
      },
      message_written = {
        "[playful] A message on the floor! A love letter. Kidding. Maybe.",
        "[teasing] You left a note! Mine says, Mai was here. And here. And over there.",
      },
      claude_asked = {
        "[cheerful] You're asking Claude for a review! Backup's here. King and Yuri are busy.",
        "[playful] Calling Claude? Don't be jealous. I'm only asking about the code.",
      },
    },
  },
}
