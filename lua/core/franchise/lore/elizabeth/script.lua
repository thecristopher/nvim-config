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
        "[low, amused] Tests are running, malysh. Come sit on my throne while we wait. <slow>On me.</slow>",
      },
      trial_passed = {
        "[cold, pleased] Every test passed, Cris. Limbo is disappointed. I am not.",
        "[purring] All green, malysh. I promised you a reward, Cris. It's waiting in my bed, wearing nothing.",
      },
      trial_failed = {
        "[flat] The tests failed. Nyet. That's not how we do things in my realm.",
        "[commanding] Red, malysh. On your knees, Cris. [break] Not for the tests. You fix those after I'm done with you.",
      },
      committing = {
        "[dry] Claude is writing your commit. In ink, not blood. This time.",
        "[smug] Drafting your commit, malysh. Bound to me. Tonight I use real rope.",
      },
      committed = {
        "[satisfied] Commit saved. In Limbo we call that a blood oath.",
        "[teasing] Committed, malysh. I love a man who <emphasis>commits</emphasis>. Now commit to me. All night. In my bed.",
      },
      pushed = {
        "[effortless] Your push went through the Stepping Disc. Don't wave. It's gone.",
        "[smirk] Pushed, malysh. One hard thrust and it's in. Save the rest for me tonight.",
      },
      pr_drafting = {
        "[impatient] Claude is drafting your pull request. Short. We don't explain ourselves.",
        "[low] Writing your PR, malysh. I'll tell them how hard you worked. <whisper>Not how loud you made me scream.</whisper>",
      },
      pr_opened = {
        "[sardonic] Your PR is open. Like a portal, with fewer screaming demons. Probably.",
        "[inviting] Pull request open, malysh. Let them come. [break] Tonight, so will you. I'll make sure of it.",
      },
      ci_passed = {
        "[dry] CI passed. Piotr would cry. He cries at everything.",
        "[possessive] Pipeline's green, malysh. I'm opening a disc straight to my bed. Your clothes stay in Limbo.",
      },
      ci_failed = {
        "[irritated] CI failed. Someone summoned demons into the pipeline.",
        "[stern] The pipeline fell, malysh. You know how I <emphasis>punish</emphasis> disappointment, Cris. Bedroom. Now.",
      },
      conflicts_cleared = {
        "[dismissive] Merge conflicts banished. Back to Limbo, all of them.",
        "[smirk] Two branches fighting for one bed, malysh. I settled it. I always end up on top. Tonight too.",
      },
      lesson_started = {
        "[stern] Lesson time. Sit. Limbo was a patient teacher. I am not.",
        "[wicked] Today's lesson is with me, malysh. Every mistake, a piece of your clothing comes off. <whisper>Make mistakes.</whisper>",
      },
      solved = {
        "[curt] Exercise solved. Clean cut. Next demon.",
        "[warm, for once] You solved it, malysh. Keep that up and tonight I let you undress me. Slowly.",
      },
      solved_twice = {
        "[approving] Two exercises in a row. Da. Keep going.",
        "[teasing] Twice already, malysh? Don't finish too fast. I want you lasting all night.",
      },
      solved_thrice = {
        "[hiding being impressed] Three in a row. Even Belasco never got that far with me.",
        "[commanding] Three, malysh. Kneel, Cris. [break] I said <emphasis>kneel.</emphasis> [soft] Good. Now kiss your way up.",
      },
      solve_failed = {
        "[cold] That submit failed. Nyet. Back to Limbo. Again.",
        "[dangerous calm] Wrong answer, malysh. That's one spanking. I'll collect tonight. Slowly.",
      },
      hint = {
        "[grudging] You bought a hint, Cris. Fine. I'll peek through a disc. Look there.",
        "[close to his ear] A hint, malysh? Then beg for it, the way you beg in bed. [break] Better. Look there.",
      },
      lesson_done = {
        "[dry] Lesson's over, Cris. You survived. Most of my students don't.",
        "[possessive] Class dismissed, malysh. Except you. Lock the door. Take it all off.",
      },
      boss_appeared = {
        "[icy, drawing the Soulsword] Belasco is here. He wants my throne. He gets neither.",
        "[contempt] Belasco again, malysh. He wants me in his bed. Only one man gets me there. You.",
      },
      boss_felled = {
        "[cold triumph] Belasco is down, Cris. Every heart mended. He met the Darkchild.",
        "[dark smile] The boss is on the floor, malysh. You're next. Floor, bed, I'm not picky.",
      },
      title_shown = {
        "[ominous] Limbo. Abandon hope. Or don't. I like it when they hope.",
        "[regal] My realm, malysh. My rules, my sword. [break] And tonight, my bed, with you tied to it.",
      },
      morning = {
        "[groggy, dry] Morning, Cris. First time in the editor. The demons are asleep. Unlike me.",
        "[smirk] You opened Neovim, malysh. After last night, Cris, I can barely walk. Worth it.",
      },
      region_arrived = {
        "[regal] You chose Limbo, Cris. I am Magik, Sorceress Supreme. Wipe your feet.",
        "[playful danger] Welcome to my realm, malysh. The demons bite, Cris. I bite <emphasis>harder</emphasis>, and you love it.",
      },
      traveled = {
        "[brisk] New repo. Through the disc. Don't let go of my hand.",
        "[amused] Switching repos, malysh? Wherever my disc opens, there's a bed. I checked.",
      },
      resting = {
        "[lazy] The editor is idle. Even Limbo needs a minute of silence.",
        "[low] Taking a break, malysh? I'll open a disc to my bed. Ten minutes is plenty for what I have in mind.",
      },
      woke = {
        "[dry] You're back, Cris. Time runs strange in Limbo. You were gone a minute. Or a year.",
        "[satisfied] Back at the keyboard, malysh. I watched you sleep, Cris. Tonight you won't. I'll be on top of you.",
      },
      expedition = {
        "[hushed] Expedition starting. Even the demons hold their breath.",
        "[whisper] We're heading out, malysh. <whisper>Not a sound.</whisper> Save your moaning for tonight.",
      },
      map_opened = {
        "[proud] The map. Every corner of Limbo belongs to me.",
        "[purring] Every corner of this map is mine, malysh. Tonight, every inch of you too.",
      },
      bestiary_opened = {
        "[cold amusement] The bestiary. Every demon I sent home. Belasco would be jealous.",
        "[smug] Every creature that tried to tame me, malysh. Only you ever got me on my back.",
      },
      chronicle_opened = {
        "[rare softness] Our chronicle. Every night in my realm. Don't tell Piotr I kept count.",
        "[possessive] Our chronicle, malysh. Every night in my bed. I counted, Cris. Tonight you beat the record.",
      },
      message_written = {
        "[dry] A message on the floor. For whoever is stupid enough to follow.",
        "[wicked] You left a message, malysh. Mine says, <whisper>bedroom, naked, now.</whisper>",
      },
      claude_asked = {
        "[reluctant] You're asking Claude for a review. A friendlier demon, I hope.",
        "[amused] Asking Claude, malysh? Fine. It reviews your code. I review you. In bed. Tonight.",
      },
    },
  },
  -- Scarlet Witch
  westview = {
    voice = "0dc74c8ebf83432290d6f454ff4e0db9",
    takes = {
      trial_started = {
        "[warm, a bit nervous] Your tests are running. Cue the laugh track, just in case.",
        "[conspiratorial] Running the tests, love. Dim the lights. Tonight's episode is the one where we never leave the bedroom.",
      },
      trial_passed = {
        "[proud] Every test passed, Cris. Not one thing in this town I had to rewrite.",
        "[playful, low] All green, love. Roll the credits. I already took the costume off.",
      },
      trial_failed = {
        "[comforting] The tests failed. Shh. Nothing here is permanent. Not even this.",
        "[teasing] A failed take, love. It's fine, Cris. I like doing it more than once. Ask last night.",
      },
      committing = {
        "[nostalgic] Claude's writing your commit. Some memories I don't want to lose.",
        "[smiling] Drafting the commit, love. Like tonight's script. Your part is me, on top, all night.",
      },
      committed = {
        "[tender] Commit saved. This one stays exactly as it is.",
        "[intimate] Committed, love. No rewriting it. And no rewriting tonight, I want you exactly like last time.",
      },
      pushed = {
        "[wistful] Your push left the Hex. I'll keep the porch light on.",
        "[amused] Pushed, love. Out there it's rated G. In our bed, [break] it's very much not.",
      },
      pr_drafting = {
        "[narrator voice] Claude's drafting your PR. Previously, on our code.",
        "[sly] Writing the PR recap, love. I'll leave out the scenes where I was screaming your name.",
      },
      pr_opened = {
        "[proud] Your pull request is open. The whole town will read it.",
        "[playful] PR's open, love. Everyone's watching. [small laugh] Tonight nobody watches. Just you, me, and no clothes.",
      },
      ci_passed = {
        "[delighted] CI passed. That's a wrap. The whole town's cheering.",
        "[suggestive] The pipeline's green, love. Dinner first. Then dessert. [break] I'm dessert.",
      },
      ci_failed = {
        "[steady] CI failed. Cut. The pipeline broke, not you. Give me your hand.",
        "[soothing, low] The pipeline broke, love. Come to bed, Cris. I'll make you forget there ever was a pipeline.",
      },
      conflicts_cleared = {
        "[relieved] Merge conflicts gone. Two realities, one home again.",
        "[satisfied] Two branches fighting over one bed, love. I merged them. That's what we do every night.",
      },
      lesson_started = {
        "[gentle director] Today's lesson. Places, everyone. You're the lead.",
        "[sultry] Rehearsal, love. The lead does <emphasis>exactly</emphasis> what the director says. The director says undress me.",
      },
      solved = {
        "[soft laugh] You solved it. Some things really are what they seem.",
        "[approving] Exercise solved, love. Good boy. Tonight's episode is rated X.",
      },
      solved_twice = {
        "[innocent] Two in a row. I didn't touch it. Not even a little red.",
        "[teasing] Two perfect takes, love. Keep those hands that good. I want them all over me tonight.",
      },
      solved_thrice = {
        "[guilty smile] Three in a row. Okay, maybe I bent reality. Just a little.",
        "[breathless] Three, love! Special episode, Cris. Late night. No commercial breaks. No clothes.",
      },
      solve_failed = {
        "[patient] That submit didn't land. Rewind. Take two.",
        "[warm, slow] Wrong answer, love. Again, slower. [break] Slower is how I like it in bed too.",
      },
      hint = {
        "[whispered cue] You bought a hint, Cris. A cue from the wings. Right there.",
        "[low] Here's your hint, love. <whisper>A little lower.</whisper> There. I'll be saying that to you tonight.",
      },
      lesson_done = {
        "[content] Lesson's done, Cris. That's the episode. Same time tomorrow.",
        "[sultry] That's the lesson, love. The after show is in our bed, and I'm the whole cast.",
      },
      boss_appeared = {
        "[tense] Agatha's here. Of course it was Agatha. Stay behind me.",
        "[jealous] Agatha's eyeing you, love. [break] Nobody gets you into bed but <emphasis>me</emphasis>.",
      },
      boss_felled = {
        "[fierce, then calm] Agatha's gone, Cris. Every heart mended. Nobody touches what's ours.",
        "[breathless] She's gone, love. Your hearts are full. Mine's racing. Take me to bed and keep it racing.",
      },
      title_shown = {
        "[sitcom bright] Westview. Our show, our rules. Roll the theme song.",
        "[intimate] Westview, love. Tonight's episode is for one viewer only, and I'm not wearing much.",
      },
      morning = {
        "[sunny] Good morning, Cris. First time in the editor today. Coffee's on. The code can wait one sip.",
        "[sleepy, flirty] You opened Neovim, love. Come back to bed, Cris. The coffee can wait. I can't.",
      },
      region_arrived = {
        "[welcoming] You chose Westview, Cris. Today I'm Wanda, and you're home.",
        "[playful] Welcome to Westview, love. Your role tonight, the husband, Cris. [break] Very method. Very hands on.",
      },
      traveled = {
        "[gentle] New repo. New set, new decade. Hold my hand.",
        "[amused] Switching repos, love? New decade. My outfit has fewer buttons. Easier to take off.",
      },
      resting = {
        "[soft] The editor's resting. Intermission. The sun's on the blinds.",
        "[low] Taking a break, love? Long commercial break. Long enough to take you to bed.",
      },
      woke = {
        "[tender] You're back, Cris. I kept the world still for you.",
        "[teasing] Back at the keyboard, love. You fell asleep before me last night. Tonight you don't get to.",
      },
      expedition = {
        "[hushed] Expedition starting. I'll turn the sound off for the whole town.",
        "[whisper] Quiet on set, love. <whisper>Just you, me, no cameras, and no clothes.</whisper>",
      },
      map_opened = {
        "[fond] The map. Every street of Westview is ours.",
        "[sly] The map, love. Our house, our street, our bedroom. Guess where I want you.",
      },
      bestiary_opened = {
        "[proud] The bestiary. Every villain who tried to break our world.",
        "[possessive] Every villain who wanted you, love. I wrote them all out. Only I get you, every night.",
      },
      chronicle_opened = {
        "[nostalgic] Our chronicle. Every episode we've lived. I'd watch them all again.",
        "[smiling] Every episode, love. The bedroom ones I replay in my head, Cris. Constantly.",
      },
      message_written = {
        "[sweet] A message on the floor. Like a note on the fridge.",
        "[playful] You left a note, love. Mine says, come upstairs. I'm already undressed.",
      },
      claude_asked = {
        "[light] You're asking Claude for a review. Even a witch needs a script doctor.",
        "[amused] Calling Claude, love. Let it fix the code. You save your energy for me tonight.",
      },
    },
  },
  -- Ada
  separate_ways = {
    voice = "a211b99d46894b6ca652f6ff2cee84f1",
    takes = {
      trial_started = {
        "[cool] Your tests are running. Let's see who's been lying to us.",
        "[teasing] Running the tests, handsome. Don't hold your breath. [break] You'll need it when I get you alone.",
      },
      trial_passed = {
        "[dry] Every test passed, Cris. I told Luis you'd manage. He owes me ten pesetas.",
        "[flirting] Clean run, handsome. I'm staying the night. <emphasis>And</emphasis> we're not sleeping.",
      },
      trial_failed = {
        "[unbothered] The tests failed. Lucky for you, I always have a plan B.",
        "[mock pout] Failing already, handsome? I hope you last longer in bed, Cris.",
      },
      committing = {
        "[low] Claude's writing your commit. Watch the door. I don't like witnesses.",
        "[sly] Drafting the commit, handsome. Lock the door. [break] The red dress comes off next.",
      },
      committed = {
        "[crisp] Commit's in. In and out. No witnesses.",
        "[satisfied] Committed, handsome. Now I've got something on you. I'll collect it in bed.",
      },
      pushed = {
        "[vanishing] Your push is out. And I was never here.",
        "[playful] Pushed, handsome. Smooth exit. Tonight I'm not leaving your bed until morning.",
      },
      pr_drafting = {
        "[businesslike] Claude's drafting your PR. Wesker likes them short. So do I.",
        "[smirk] Writing the pull request, handsome. Leaving out the part where you begged me not to stop.",
      },
      pr_opened = {
        "[cool] Your pull request is open. Let's see who bites first.",
        "[sultry] PR's open, handsome. Who bites first? [small laugh] Me. Your neck. Tonight.",
      },
      ci_passed = {
        "[pleased] CI passed. Smooth. Almost as smooth as me.",
        "[low] Pipeline's green, handsome. Business first. [break] Then I take you to bed.",
      },
      ci_failed = {
        "[sharp] CI caught it. Sloppy. That's not like you.",
        "[teasing] CI caught you, handsome. I never get caught, Cris. Unless it's you, pinning me to the bed.",
      },
      conflicts_cleared = {
        "[dismissive] Merge conflicts cleared. Nobody plays my part but me.",
        "[cool] Two branches, one bed, handsome. I took the one on top. I always do.",
      },
      lesson_started = {
        "[crisp] Today's lesson. Pay attention. I don't repeat myself.",
        "[commanding] Lesson starts now, handsome. Hands where I can see them. Tonight, hands all over me.",
      },
      solved = {
        "[dry praise] Exercise solved. Leon takes three tries for that one.",
        "[low] You solved it, handsome. Keep that up and tonight I let you catch me. And undress me.",
      },
      solved_twice = {
        "[mild surprise] Two in a row. You're full of surprises.",
        "[amused] Two, handsome. I like you confident. Bring that to bed tonight.",
      },
      solved_thrice = {
        "[warning smile] Three in a row. Careful. I could get used to this.",
        "[slow] Three, handsome. You win a prize, Cris. It's red, it unzips in the back, and I'm inside it.",
      },
      solve_failed = {
        "[light] That submit missed. Happens to the best. Don't make it a habit.",
        "[teasing] Wrong answer, handsome. Try harder to get me into bed. I don't come that easy.",
      },
      hint = {
        "[conspiratorial] You bought a hint, Cris. You owe me one. Look behind the obvious.",
        "[whispering] Here's your hint, handsome. <whisper>Follow the grappling line.</whisper> It ends in my bed.",
      },
      lesson_done = {
        "[detached] Lesson's done, Cris. Same time tomorrow. If I feel like it.",
        "[leaving] Class is over, handsome. Next lesson's private, in my room. Bring nothing. Wear nothing.",
      },
      boss_appeared = {
        "[irritated] Pesanta's here. Big, ugly, and in my scene. Stay out of my line of fire.",
        "[dry] Pesanta wants a piece of you, handsome. Get in line. I get you first. All night.",
      },
      boss_felled = {
        "[businesslike] Pesanta's down, Cris. Every heart mended. I keep the amber, you keep the credit.",
        "[satisfied] Boss is down, handsome. You're out of breath. Good. That's how I want you in bed.",
      },
      title_shown = {
        "[smooth] Separate Ways. Different paths, same ending. Me, one step ahead.",
        "[sultry] Separate Ways, handsome. We split up. We always end up in the same bed.",
      },
      morning = {
        "[aloof] Opening the editor this early, Cris? You must like me.",
        "[teasing] Morning, handsome. First time in Neovim today, Cris. You kept me up all night. I'm not complaining.",
      },
      region_arrived = {
        "[mysterious] You picked Separate Ways, Cris. Ada Wong. Today, I work for you.",
        "[low] You chose me, handsome. Good choice, Cris. Now do exactly as I say. Starting with the lights.",
      },
      traveled = {
        "[cool] New repo. Don't look so surprised to see me there.",
        "[amused] Switching repos, handsome? I know every dark corner. And what I'll do to you in each one.",
      },
      resting = {
        "[relaxed] Editor's idle. I'll keep watch.",
        "[low] Taking a break, handsome? Lie back. I'll get on top. [break] I keep watch better from there.",
      },
      woke = {
        "[dry] Back at the keyboard, Cris? Don't make napping a habit.",
        "[smirk] You're back, handsome. I waited in your bed, Cris. In the red dress. Not anymore.",
      },
      expedition = {
        "[clipped] Expedition. Radio silence. Quick and clean.",
        "[whisper] Radio off, handsome. <whisper>Nobody hears you moan.</whisper>",
      },
      map_opened = {
        "[confident] The map. I already know three ways out.",
        "[sly] Three ways out on this map, handsome. And one way into my bed.",
      },
      bestiary_opened = {
        "[cool] The bestiary. Every villain who got in our way. Short list.",
        "[dry] Every man who tried to pin me down, handsome. Only you ever got me on my back.",
      },
      chronicle_opened = {
        "[guarded] Our chronicle. Every job we pulled. Not bad for strangers.",
        "[low] Every night together on paper, handsome. The real version is classified, Cris. And very loud.",
      },
      message_written = {
        "[cool] A message on the floor. Unsigned, I hope.",
        "[sultry] You left a note, handsome. Mine's in lipstick on your mirror. It says, bed, now.",
      },
      claude_asked = {
        "[clipped] You're asking Claude for a review. A contact. Don't ask who.",
        "[teasing] Calling Claude, handsome? Relax. It checks your code. I check you. Tonight. Everywhere.",
      },
    },
  },
  -- Shadowheart
  moonrise_towers = {
    voice = "9c23004e059f43c0bca8cbbdfa0a0d3a",
    takes = {
      trial_started = {
        "[dry prayer] Your tests are running. Selûne, now would be nice.",
        "[sardonic] Running the tests. If something breaks, I'll heal it. In my tent. [break] Slowly.",
      },
      trial_passed = {
        "[grudging] Every test passed, Cris. Fine. I'm impressed. Don't let it go to your head.",
        "[warm, low] All green. Selûne smiles on you. I'll do a lot more than smile tonight. Without the robe.",
      },
      trial_failed = {
        "[sighing] The tests failed. Sit down. Let me see the wound.",
        "[sly] Red, Cris. Take off the armor and lie down. I'll heal you with a lot more than prayers.",
      },
      committing = {
        "[dry] Claude's writing your commit. Unlike Shar's secrets, this one we keep.",
        "[teasing] Drafting the commit. Some vows are spoken in temples. Mine get moaned in the tent.",
      },
      committed = {
        "[sardonic] Commit saved. More loyal than some clerics I could name.",
        "[soft command] Committed. Like you'll be tonight. Under me. Don't argue.",
      },
      pushed = {
        "[gentle] Your push is out. May the moonlight find it a path.",
        "[smiling] Pushed. The moon's out. You know what that means. The robe comes off.",
      },
      pr_drafting = {
        "[wry] Claude's drafting your pull request. Let's hope the reviewers are merciful.",
        "[low] Writing your PR. Mercy is my specialty. Tonight you'll beg me for it, in bed.",
      },
      pr_opened = {
        "[confident] Your PR is open. Let them judge. I already have. It's good.",
        "[sly] PR's open. They'll inspect every inch. I'd rather inspect you. Tonight. Undressed.",
      },
      ci_passed = {
        "[pleased] CI passed. By the moonlight, you actually did it.",
        "[low] Pipeline's green. Come to the tent. The mace stays outside. [break] The restraints don't.",
      },
      ci_failed = {
        "[weary] CI failed. Another curse. We've broken worse than a pipeline.",
        "[strict, playful] The pipeline broke, Cris. That calls for a punishment. In my tent. You'll enjoy every minute.",
      },
      conflicts_cleared = {
        "[satisfied] Merge conflicts settled. Shar and Selûne could never manage that.",
        "[smirk] Dark and light, tangled together, finally at peace. Like us in the bedroll last night.",
      },
      lesson_started = {
        "[stern] Today's lesson. Pay attention. I'm not repeating myself to a goblin.",
        "[strict] Lesson starts now. Every mistake earns a mark. Tonight I collect them, one by one, in bed.",
      },
      solved = {
        "[grudging] Exercise solved. Hm. Not bad.",
        "[low] You solved it. Keep that up and tonight I'll show you what I really do in the dark.",
      },
      solved_twice = {
        "[suspicious] Two in a row. Trying to impress me? [break] It's working. A little.",
        "[amused] Two. Careful. I reward devotion. In private. Undressed.",
      },
      solved_thrice = {
        "[exasperated smile] Three in a row. Fine. I'm impressed. Happy now?",
        "[breathy] Three, Cris. You've earned a blessing. Kneel. [break] Not like that. [small laugh] Fine, like that.",
      },
      solve_failed = {
        "[wincing] That submit stung. Hold still. I'll heal it, then you try again.",
        "[dry] Wrong answer. Shar would whip you. I'll do worse. I'll tease you all night and make you wait.",
      },
      hint = {
        "[conspiratorial] You bought a hint, Cris. Don't tell Lae'zel I helped. There.",
        "[whispered] Your hint. <whisper>Gently.</whisper> Right there. That's what I'll whisper to you tonight, too.",
      },
      lesson_done = {
        "[soft, grudging] Lesson's done, Cris. You did well. Don't make me say it twice.",
        "[inviting] Lesson's over. Astarion's out hunting. [break] The tent's ours. Get in. Get undressed.",
      },
      boss_appeared = {
        "[tense] Ketheric Thorm is here. Of course he wants the spotlight. Stay behind me.",
        "[possessive] Ketheric's after you. He'll die trying. Nobody touches you but me. In bed or out.",
      },
      boss_felled = {
        "[tired, wry] Ketheric's dead, Cris. Every heart mended. I wasn't in the mood to heal you again.",
        "[warm] The boss is down and you're bleeding. [break] Bed. I'll kiss every wound better.",
      },
      title_shown = {
        "[ominous] Moonrise Towers. Leave the light behind. You won't need it.",
        "[low] Moonrise Towers. The dark isn't scary here. Not with me in it. Naked.",
      },
      morning = {
        "[dry, caring] Morning, Cris. First time in the editor today, and you look terrible. Come here.",
        "[smirk] You opened Neovim, Cris. You were very devoted last night. The whole camp heard. Let them hear again tonight.",
      },
      region_arrived = {
        "[guarded] You chose Moonrise Towers, Cris. Shadowheart. Cleric, skeptic, yours.",
        "[teasing] You picked me again, Cris. Admit it. You want the cleric in your bed.",
      },
      traveled = {
        "[alert] New repo. Keep your weapon close, and me closer.",
        "[sly] Switching repos? Same tent. Pack the good bedroll. We're wearing it out.",
      },
      resting = {
        "[soft] The editor's idle. Long rest. Sit by the fire.",
        "[low] Long rest. Lie down with me. I'll tend to every wound. <slow>With my lips.</slow>",
      },
      woke = {
        "[gentle] You're back, Cris. You were mumbling about owlbears.",
        "[amused] Back at the keyboard, Cris. You slept through my prayers. Tonight you'll be awake for every one.",
      },
      expedition = {
        "[hushed] Expedition starting. Silence. Even Shar would approve.",
        "[whisper] We're heading out. <whisper>The night is ours. Keep quiet now, you won't later.</whisper>",
      },
      map_opened = {
        "[knowing] The map. Moonrise is a maze, but I know its darkest corners.",
        "[low] I know every dark corner on this map. Tonight I show you the one in my tent.",
      },
      bestiary_opened = {
        "[proud] The bestiary. Every villain we put down. I healed you through all of them.",
        "[dry] Every monster we've faced. None of them kept me up all night. You did.",
      },
      chronicle_opened = {
        "[soft] Our chronicle. Every night under the moon, with you.",
        "[teasing] Every night we've had, Cris. Some I'd confess. Most I'd repeat. Tonight.",
      },
      message_written = {
        "[wry] A message on the floor. Something helpful, for once. Not like Astarion's.",
        "[sly] You left a message. Mine says, <emphasis>try praying</emphasis>. On your knees. In my tent.",
      },
      claude_asked = {
        "[firm] You're asking Claude for a review. Good. Not Shar. Never again.",
        "[amused] Asking Claude? Fine. You confess your code to it. Everything else you confess to me. In bed.",
      },
    },
  },
  -- Psylocke, played as Kwannon
  danger_room = {
    voice = "fb89e1ed27b6409da8648554f15ae8fb",
    takes = {
      trial_started = {
        "[quiet, precise] Your tests are running. A ninja waits without moving. Hai.",
        "[low, amused] Running the tests, anata. While we wait, untie my sash. <slow>Slowly.</slow>",
      },
      trial_passed = {
        "[calm pride] Every test passed, Cris. Yoshi. One draw, one cut.",
        "[low] All green, anata. I've seen in your mind how you want to celebrate. Tonight. On my futon.",
      },
      trial_failed = {
        "[composed] The tests failed. A blade dulls. You sharpen it. Again.",
        "[teasing] Red, anata. Your mind wandered to me, Cris. Fix the tests first. Then your hands can wander too.",
      },
      committing = {
        "[crisp] Claude is writing your commit. Few words. The Hand never left notes.",
        "[sly] Drafting the commit, anata. And no, what you want to do to me does not go in the message.",
      },
      committed = {
        "[cool] Commit saved. Sheathe the katana.",
        "[low] Committed, anata. Now commit to me. All night. On the futon.",
      },
      pushed = {
        "[precise] Your push is out. One draw, one cut, done.",
        "[purring] Pushed, anata. Clean, fast, deep. Tonight, the same. With me.",
      },
      pr_drafting = {
        "[dry] Claude is drafting your pull request. Short. Like a death poem.",
        "[amused] Writing your PR, anata. I could tell them what you dreamt about me. In detail. I won't.",
      },
      pr_opened = {
        "[knowing] Your PR is open. I already read the reviewers. They will approve.",
        "[sly] PR's open, anata. Everyone sees your work. Only I see what you want to do to me. [break] I want it too.",
      },
      ci_passed = {
        "[pleased] CI passed. Precise. Sugoi.",
        "[low] Pipeline's green, anata. Tonight the kimono stays on the floor.",
      },
      ci_failed = {
        "[calm] CI failed. Breathe, Cris. We find the weak point, and we cut.",
        "[teasing] The pipeline broke, anata. You're tense, Cris. I can feel it. Lie down. I know exactly where to press.",
      },
      conflicts_cleared = {
        "[cool] Merge conflicts resolved. Two blades. One edge.",
        "[smirk] Two branches fighting, anata. I made them agree. Tonight we agree on everything. In bed.",
      },
      lesson_started = {
        "[sensei] Today's lesson. Bow, then begin. I will know if your mind wanders.",
        "[strict] Training starts now, anata. Eyes on the blade. [break] Not on me. Tonight, yes.",
      },
      solved = {
        "[curt] Exercise solved. Clean cut.",
        "[soft] You solved it, anata. Keep that focus and tonight I reward it. On the futon. Slowly.",
      },
      solved_twice = {
        "[approving] Two in a row. Yoshi. Your blade is sharp today.",
        "[amused] Two, anata. You're showing off for me. I can hear your thoughts. Very naughty ones.",
      },
      solved_thrice = {
        "[rare warmth] Three in a row. Even the masters of the Hand would bow.",
        "[low] Three, anata. I've seen the reward you want, Cris. [break] Hai. All of it. Tonight.",
      },
      solve_failed = {
        "[patient] That submit missed. Again. A hundred cuts, then a thousand.",
        "[low] Close, anata. Submit again. And tonight, do it to me like that. <slow>Slowly.</slow>",
      },
      hint = {
        "[quiet] You bought a hint, Cris. Let me in your mind a moment. There.",
        "[whispering] Your hint, anata. <whisper>Let me in.</whisper> [break] Mmm. Look there. Tonight, I let you in.",
      },
      lesson_done = {
        "[satisfied] Lesson's over, Cris. Good form. Tomorrow we sharpen it.",
        "[sly] Class dismissed, anata. Very good form. Show me that form tonight. In bed.",
      },
      boss_appeared = {
        "[cold] Mister Sinister. He made me a weapon once. Never again.",
        "[contempt] Sinister wants inside your head, anata. Only I get into your head. And into your bed.",
      },
      boss_felled = {
        "[cool triumph] Sinister is down, Cris. Every heart mended. The psychic katana never misses.",
        "[breathless] The boss is down, anata. Your pulse is racing. Mine too. Futon. Now.",
      },
      title_shown = {
        "[elegant] The Danger Room. Draw your blade.",
        "[low] The Danger Room, anata. Tonight the only danger is me, out of this suit.",
      },
      morning = {
        "[quiet] Ohayou, Cris. First time in the editor today. Your mind is clear. Rare.",
        "[teasing] Ohayou, anata. You opened Neovim, but your thoughts are still in my bed, Cris. Mine too.",
      },
      region_arrived = {
        "[formal] You chose the Danger Room, Cris. Kwannon. Psylocke. Mind the lasers.",
        "[sly] You picked me, anata. I knew, Cris. I put the idea there. Along with a few others for tonight.",
      },
      traveled = {
        "[calm] New repo. I already read every mind in it.",
        "[amused] Switching repos, anata? Everyone here is boring. Except you. In my bed.",
      },
      resting = {
        "[gentle] The editor is idle. Close your eyes. Let your mind rest.",
        "[low] Taking a break, anata? Close your eyes. In your head, I'm already undressing.",
      },
      woke = {
        "[soft] You're back, Cris. You rested well. I made sure of it.",
        "[smirk] Back at the keyboard, anata. You dreamt of me, Cris. I was there. Tonight we do it for real.",
      },
      expedition = {
        "[serene] Expedition starting. Silence. Like a shadow on the roof.",
        "[whisper] We're heading out, anata. <whisper>I'll speak straight into your head. Only filthy things.</whisper>",
      },
      map_opened = {
        "[tactical] The map. Every exit, every blind spot.",
        "[sly] Every blind spot on this map, anata. Perfect places to corner you and kiss you.",
      },
      bestiary_opened = {
        "[cool] The bestiary. Every enemy we cut down. None saw the blade.",
        "[dry] Every mind I've broken, anata. Yours I'd rather keep up all night.",
      },
      chronicle_opened = {
        "[fond] Our chronicle. Every session, every scar. All worth it.",
        "[low] Every night we shared, anata. I felt them from both sides, Cris. Twice the pleasure.",
      },
      message_written = {
        "[dry] A message on the floor. A ninja leaves none. You may.",
        "[teasing] You left a note, anata. Mine is in your head. It says, my futon, tonight, nothing on.",
      },
      claude_asked = {
        "[crisp] You're asking Claude for a review. Another mind. Fine.",
        "[amused] Asking Claude, anata? Its mind is boring. Yours is full of me. Undressed.",
      },
    },
  },
  -- Triss, cast with Shadowheart's voice
  limgrave = {
    voice = "9c23004e059f43c0bca8cbbdfa0a0d3a",
    takes = {
      trial_started = {
        "[steady] Your tests are running. Here comes the fog gate.",
        "[teasing] Running the tests, Tarnished. Summon sign's down. Touch it and I'm in your bed.",
      },
      trial_passed = {
        "[warm] Every test passed, Cris. Rest at grace with me a moment.",
        "[low] All green, Tarnished. I'll light the grace. You take off my armor.",
      },
      trial_failed = {
        "[encouraging] The tests failed. We die, we rise. Come on, Tarnished.",
        "[smiling] You died again, Tarnished. Good. I like starting over with you, Cris. Especially in bed.",
      },
      committing = {
        "[calm] Claude's writing your commit. Carving it in the stone.",
        "[sly] Drafting the commit, Tarnished. Then we rest at grace. [break] We won't be resting.",
      },
      committed = {
        "[warm] Commit saved. A grace lit, so we never lose this point.",
        "[amused] Committed, Tarnished. In the game you control me. Tonight I control you.",
      },
      pushed = {
        "[bright] Your push is out. Torrent couldn't have carried it faster.",
        "[playful] Pushed, Tarnished. Torrent's waiting. He's not the only one you'll ride tonight.",
      },
      pr_drafting = {
        "[thoughtful] Claude's drafting your pull request. A message for the ground.",
        "[teasing] Writing your PR, Tarnished. Liar ahead. Treasure ahead. [break] Me, naked, ahead.",
      },
      pr_opened = {
        "[curious] Your PR is open. Let's see the appraisals.",
        "[low] PR's open, Tarnished. Everyone can rate it. Only you get to touch me.",
      },
      ci_passed = {
        "[reverent] CI passed. The Erdtree's light is on us.",
        "[sly] Pipeline's green, Tarnished. Great runes restored. Now take me to bed.",
      },
      ci_failed = {
        "[determined] CI failed. Lost runes. We go back to the bloodstain.",
        "[low] The pipeline broke, Tarnished. Your flasks are empty, Cris. Come to bed. I'll refill you all night.",
      },
      conflicts_cleared = {
        "[relieved] Merge conflicts gone. The fog lifted.",
        "[teasing] The fog lifted, Tarnished. Two bodies, one bedroll. Finally.",
      },
      lesson_started = {
        "[warm] Today's lesson. Same as Stormveil. Patience, and a good shield.",
        "[playful] Lesson time, Tarnished. You lead, I follow. Tonight in bed, I lead.",
      },
      solved = {
        "[pleased] Exercise solved. Another step toward the Erdtree.",
        "[low] You solved it, Tarnished. Keep that up and tonight I'm your reward. All of me.",
      },
      solved_twice = {
        "[laughing] Two in a row. Margit would be nervous.",
        "[teasing] Two, Tarnished. Strong build today. Save that stamina for tonight.",
      },
      solved_thrice = {
        "[delighted] Three in a row. You're not maidenless anymore.",
        "[low] Three, Tarnished. You're not maidenless anymore, Cris. [break] Come and claim me.",
      },
      solve_failed = {
        "[gentle] That submit failed. You died. We rise. Again.",
        "[amused] Wrong answer, Tarnished. I love watching you get back up. Tonight, pull me down with you.",
      },
      hint = {
        "[helpful] You bought a hint, Cris. A message on the ground, just for you. Look there.",
        "[whispering] Your hint, Tarnished. <whisper>Try finger, but hole.</whisper> [small laugh] Kidding. Look there.",
      },
      lesson_done = {
        "[content] Lesson's done, Cris. A good place to rest.",
        "[low] Lesson's over, Tarnished. The grace is warm and my armor's off. Don't make me wait.",
      },
      boss_appeared = {
        "[steady] Margit's here. Foul Tarnished, he says. That's us. Stay close.",
        "[defiant] Margit wants you on your knees, Tarnished. Only I get to do that.",
      },
      boss_felled = {
        "[triumphant] Margit's down, Cris. Great enemy felled. Every heart restored.",
        "[breathless] Great enemy felled, Tarnished. My heart's pounding. Take me to bed and keep it that way.",
      },
      title_shown = {
        "[warm] Elden Ring. I'm Triss, and you made me for this.",
        "[sly] You made me, Tarnished. Every slider. Every curve. Tonight, put them to use.",
      },
      morning = {
        "[soft] Morning, Cris. First time in the editor today. The grace waited for us.",
        "[teasing] You opened Neovim, Tarnished. You kept me up past the Roundtable curfew, Cris. Do it again tonight.",
      },
      region_arrived = {
        "[gentle] You chose Limgrave, Cris. I'm Triss. Our first steps, together.",
        "[playful] Triss, your character, Tarnished. You control me, Cris. [break] Until we're in bed.",
      },
      traveled = {
        "[curious] New repo. New grace found. Let's see what's beyond the fog.",
        "[sly] Switching repos, Tarnished. Fresh bedroll. Let's mess it up.",
      },
      resting = {
        "[calm] The editor's idle. Rest at grace. The fire's small but warm.",
        "[low] Taking a break, Tarnished? Sit by me. Closer. Armor off. The fire's warm enough.",
      },
      woke = {
        "[gentle] You're back, Cris. Flasks refilled.",
        "[amused] Back at the keyboard, Tarnished. You slept, Cris. Tonight you won't.",
      },
      expedition = {
        "[hushed] Expedition starting. Quiet. Just the wind across Stormhill.",
        "[whisper] Heading out, Tarnished. <whisper>Nobody's invading tonight but you.</whisper>",
      },
      map_opened = {
        "[focused] The map. Let's find the next grace.",
        "[sly] The map, Tarnished. I marked a cave nearby. Very private. Bring nothing to wear.",
      },
      bestiary_opened = {
        "[proud] The bestiary. Every enemy we've felled. The runes were good.",
        "[teasing] You were rough with all of them, Tarnished. Be rough with me tonight.",
      },
      chronicle_opened = {
        "[soft] Our chronicle. Every night at grace, with you.",
        "[low] Every grace we stopped at, Tarnished. At most of them we didn't rest, Cris. We undressed.",
      },
      message_written = {
        "[earnest] You left a message on the ground. For the next Tarnished.",
        "[playful] Nice message, Tarnished. Mine says, try kissing, but tongue.",
      },
      claude_asked = {
        "[respectful] You're asking Claude for a review. Counsel from the Roundtable.",
        "[amused] Asking Claude, Tarnished? Fine. Nobody at the Roundtable gets you into bed but me.",
      },
    },
  },
  -- Jill
  raccoon_city = {
    voice = "8c2ead349a024794af1381200adbd5d9",
    takes = {
      trial_started = {
        "[focused] Your tests are running. Here comes the clock tower bell.",
        "[dry] Running the tests, rookie. Hands where I can see them. [break] Tonight, hands on me.",
      },
      trial_passed = {
        "[relieved] Every test passed, Cris. Bomb defused.",
        "[low] All green, rookie. Master of unlocking. Tonight I unlock you. Then the cuffs.",
      },
      trial_failed = {
        "[determined] The tests failed. Another locked door. Good thing I've got the lockpick.",
        "[teasing] Red, rookie. You're tense, Cris. Bed. I know how to loosen you up.",
      },
      committing = {
        "[urgent] Claude's typing your commit. Cover me at the typewriter.",
        "[dry] Drafting the commit, rookie. Don't distract me. [break] Fine. Take my beret off. Then the rest.",
      },
      committed = {
        "[satisfied] Commit saved. No ink ribbon wasted.",
        "[smirk] Committed, rookie. Cuffs on. Yours. To my bed. Tonight.",
      },
      pushed = {
        "[brisk] Your push is out. Heading for the extraction point.",
        "[low] Pushed, rookie. Extraction's in ten. Plenty of time to get you undressed.",
      },
      pr_drafting = {
        "[professional] Claude's writing your PR. Short and true, for the chief.",
        "[dry] Writing the pull request, rookie. Leaving out what we did in the safe room.",
      },
      pr_opened = {
        "[wry] Your PR is open. Requesting backup. Not Brad.",
        "[teasing] PR's open, rookie. Everybody wants a look. Only I get to take your clothes off.",
      },
      ci_passed = {
        "[calm] CI passed. Area secure.",
        "[low] Pipeline's green, rookie. Safe room's free. Bring the cuffs. Leave the clothes.",
      },
      ci_failed = {
        "[angry] CI failed. Umbrella's fingerprints are all over this pipeline.",
        "[steady] The pipeline went down, rookie. Don't panic, Cris. I'm very good under pressure. Under you too.",
      },
      conflicts_cleared = {
        "[satisfied] Merge conflicts cleared. Two wires, one cut, no boom.",
        "[sly] Crossed wires, rookie. I always know what to pull. Tonight it's your shirt.",
      },
      lesson_started = {
        "[brisk] Today's lesson. Same as S.T.A.R.S. training, less screaming.",
        "[teasing] Training, rookie. I'll be strict. You'll be sore tomorrow, and not from the exercises.",
      },
      solved = {
        "[clipped] Exercise cleared.",
        "[low] You solved it, rookie. Keep that up and tonight the tube top comes off for you.",
      },
      solved_twice = {
        "[pleased] Two in a row. Barry would be proud.",
        "[amused] Two, rookie. Steady hands. I want them on me tonight.",
      },
      solved_thrice = {
        "[impressed] Three in a row. You'd make S.T.A.R.S.",
        "[sly] Three, rookie. Your reward's in the safe room, Cris. Wearing a tube top. Not for long.",
      },
      solve_failed = {
        "[calm] That submit jammed. Clear it and go again.",
        "[teasing] Wrong answer, rookie. Relax your grip. [break] Save the tight grip for me.",
      },
      hint = {
        "[helpful] You bought a hint, Cris. Let me pick this one. Look there.",
        "[whispering] Your hint, rookie. Every lock has a sweet spot. <whisper>So do I. You know where.</whisper>",
      },
      lesson_done = {
        "[satisfied] Lesson's done, Cris. Good work, rookie.",
        "[low] Lesson's over, rookie. Debrief's in my bed. Uniform off.",
      },
      boss_appeared = {
        "[alarmed] It's Nemesis! He wants the whole scene. Move!",
        "[protective] Nemesis again, rookie. He wants S.T.A.R.S. <emphasis>You</emphasis> are mine.",
      },
      boss_felled = {
        "[breathing hard] Nemesis is down, Cris. Every heart mended. Stay sharp, he gets back up.",
        "[breathless] Boss is down, rookie. My heart's racing. [break] Bed. Don't you dare calm it down.",
      },
      title_shown = {
        "[grim] Raccoon City. The last escape.",
        "[low] Raccoon City, rookie. Nemesis wants S.T.A.R.S. I just want you in my bed.",
      },
      morning = {
        "[brisk] Morning, Cris. First time in the editor today. Check your ammo, then the code.",
        "[teasing] You opened Neovim, rookie. You're still wearing my handcuff, Cris. Tonight, the other one too.",
      },
      region_arrived = {
        "[resolute] You chose Raccoon City, Cris. Jill Valentine, S.T.A.R.S. The city falls, not us.",
        "[sly] You picked me, rookie. Smart, Cris. I get into places nobody else can. Your bed, tonight.",
      },
      traveled = {
        "[alert] New repo. Check your corners.",
        "[dry] Switching repos, rookie. Locked doors everywhere. Lock ours behind us.",
      },
      resting = {
        "[calm] The editor's idle. Safe room. The music's playing. Breathe.",
        "[low] Taking a break, rookie? Door's locked. Clothes off. Both of us.",
      },
      woke = {
        "[warm] You're back, Cris. I kept watch.",
        "[teasing] Back at the keyboard, rookie. I kept the cuffs warm, Cris. They're for you. Tonight.",
      },
      expedition = {
        "[hushed] Expedition starting. Radio silence. One clean take.",
        "[whisper] Heading out, rookie. <whisper>Nobody's coming to rescue you from me.</whisper>",
      },
      map_opened = {
        "[tactical] The map. Plan the route before he finds us.",
        "[dry] Every room I've unlocked on this map, rookie. My bedroom's next. You're coming.",
      },
      bestiary_opened = {
        "[grim] The bestiary. Every villain we put down. Long list, short ammo.",
        "[amused] Every B.O.W. we stopped, rookie. None of them kept me up all night like you.",
      },
      chronicle_opened = {
        "[fond] Our chronicle. Every night we got out alive.",
        "[low] Every night we survived, rookie. And every night after, in the safe room bed, Cris.",
      },
      message_written = {
        "[dry humor] A message on the floor. Barry, if you read this, no sandwich jokes.",
        "[sly] You left a note, rookie. Mine says, the master of unlocking was here. Twice.",
      },
      claude_asked = {
        "[into the radio] You're asking Claude for a review. Radioing for intel.",
        "[teasing] Calling Claude, rookie? Relax. Carlos isn't my type. You are. In my bed.",
      },
    },
  },
  -- Malenia
  haligtree = {
    voice = "b797aa08ed774aa3bbab09db3254817e",
    takes = {
      trial_started = {
        "[solemn] Your tests begin.",
        "[slow] The tests begin. <slow>Hold still.</slow> Tonight, you will not.",
      },
      trial_passed = {
        "[calm] Every test passed, Cris. A clean cut.",
        "[slow] All green. Kneel. Your reward waits in my bed.",
      },
      trial_failed = {
        "[measured] The tests failed. The rot blooms. We contain it.",
        "[low] A failure, Cris. Rise. [break] Then fall into my bed.",
      },
      committing = {
        "[solemn] Claude writes your commit. A vow.",
        "[soft] A vow is written. Spoken once. Kept all night, beneath me.",
      },
      committed = {
        "[proud] Your commit is sealed. A promise kept.",
        "[slow] Sealed. I have never known defeat. Except in your bed.",
      },
      pushed = {
        "[serene] Your push is sent. On wings.",
        "[low] Sent. Now my wings fold. Around you. In bed.",
      },
      pr_drafting = {
        "[terse] Claude writes your plea. Few words.",
        "[slow] Your pull request. I do not plead. Tonight I will. For you.",
      },
      pr_opened = {
        "[proud] Your pull request is open. Let them judge. My blade already has.",
        "[low] It is open. Let them look. Only you may undress me.",
      },
      ci_passed = {
        "[solemn pride] CI passed. My blade has never known defeat.",
        "[soft] The pipeline holds. Remove my helm. [break] Then the rest.",
      },
      ci_failed = {
        "[steady] CI fell. We rise. Together.",
        "[low] The pipeline fell, Cris. Come to bed. I will make you forget it.",
      },
      conflicts_cleared = {
        "[curt] The merge conflict is severed. Clean.",
        "[slow] Two branches. One bed. Joined.",
      },
      lesson_started = {
        "[commanding] Today's lesson. Draw your blade.",
        "[low] The lesson begins. Follow my rhythm. Tonight, you set it.",
      },
      solved = {
        "[cool] Exercise solved. A clean strike.",
        "[slow] Good. Tonight you are rewarded. <slow>Slowly.</slow> All night.",
      },
      solved_twice = {
        "[measured] Two in a row. The dance continues.",
        "[soft] Twice. You move well. I want that in my bed.",
      },
      solved_thrice = {
        "[praise] Three in a row. You move like the waterfowl.",
        "[slow] Three, Cris. Waterfowl Dance. [break] Tonight I dance on you.",
      },
      solve_failed = {
        "[firm] Your submit fell. Rise. Again.",
        "[low] You fell. Stay down. I will climb on top.",
      },
      hint = {
        "[terse] You asked for a hint, Cris. Watch my blade. There.",
        "[whisper] Your hint. Watch my hand. <whisper>Tonight it is on you.</whisper> There.",
      },
      lesson_done = {
        "[gentle] The lesson is done, Cris. You did well. Rest now.",
        "[low] Enough. You are spent. I am not. Bed.",
      },
      boss_appeared = {
        "[cold] Radahn. We meet again. This time, my love watches.",
        "[fierce] Radahn seeks what is mine. Your bed is mine. He will rot.",
      },
      boss_felled = {
        "[solemn] Radahn falls, Cris. Every heart mended. As all must.",
        "[slow] He falls. Your hearts, mended. Mine, undone. Take me.",
      },
      title_shown = {
        "[ethereal] Elphael. The Haligtree sleeps.",
        "[slow] Elphael. Scarlet aeonia blooms. Undress me beneath it.",
      },
      morning = {
        "[quiet] Morning, Cris. You open the editor. The rot sleeps. I do not.",
        "[soft] You return to Neovim, Cris. You stayed in my bed all night. Stay again.",
      },
      region_arrived = {
        "[formal] You chose Elphael, Cris. I am Malenia. Blade of Miquella.",
        "[low] I am Malenia, Cris. Blade of Miquella. In your bed, yours alone.",
      },
      traveled = {
        "[calm] A new repo. Follow my wings.",
        "[low] A new land. Stay beneath my wings. And beneath me.",
      },
      resting = {
        "[soft] The editor rests. The snow is quiet.",
        "[low] Rest. My armor is off. Only for you.",
      },
      woke = {
        "[gentle] You return, Cris. I watched over you.",
        "[slow] You return, Cris. I watched you sleep. Tonight, no sleep.",
      },
      expedition = {
        "[hushed] The expedition begins. Silence. As in the Haligtree snow.",
        "[whisper] We set out. <whisper>Silence. Until I have you alone.</whisper>",
      },
      map_opened = {
        "[regal] The map. All these lands, ours.",
        "[low] The lands. And you. All of it, mine. You first.",
      },
      bestiary_opened = {
        "[cold] The bestiary. All who fell to us. A long rot.",
        "[proud] All who fell before me. You fell into my bed.",
      },
      chronicle_opened = {
        "[soft] Our chronicle. Every battle at your side. Never defeated.",
        "[low] Every night, Cris. Every surrender. Mine, in your arms.",
      },
      message_written = {
        "[terse] Your message is left. For whoever follows.",
        "[slow] A mark. Here, my armor fell.",
      },
      claude_asked = {
        "[reluctant] You seek Claude's review. Counsel. Rarely needed.",
        "[low] You ask Claude. Do not fear. None but you shares my bed.",
      },
    },
  },
  -- Raven
  azarath = {
    voice = "f9eb6364c86d428bb8b78dbdc44a176f",
    takes = {
      trial_started = {
        "[monotone] Your tests are running. Azarath Metrion Zinthos.",
        "[flat] Running the tests. Breathe in. [break] Out. Good. You'll need that tonight, in my room.",
      },
      trial_passed = {
        "[deadpan] Every test passed, Cris. I'm not smiling. Almost.",
        "[low] All green. My room. Lights off. Clothes off. Very close.",
      },
      trial_failed = {
        "[calm] The tests failed. Breathe. It passes.",
        "[flat] Red, Cris. I'll heal it. Hands on. Then my hands go elsewhere.",
      },
      committing = {
        "[quiet] Claude's writing your commit. Quietly.",
        "[deadpan] Drafting the commit. Don't hover. [break] Unless it's over me. In bed.",
      },
      committed = {
        "[flat] Commit saved. Good.",
        "[strained calm] Committed. I'm keeping my emotions under control. Tonight I won't. Warn the neighbors.",
      },
      pushed = {
        "[low] Your push is gone. Into the dark.",
        "[flat] Pushed into the dark. Tonight I take you there. In my bed.",
      },
      pr_drafting = {
        "[annoyed] Claude's drafting your PR. Don't hover.",
        "[deadpan] Writing your pull request. Fewer words, more action. Especially in bed.",
      },
      pr_opened = {
        "[bored] Your pull request is open. Wake me when the reviews come in.",
        "[flat] PR's open. Everyone can see it. I prefer things private. Like you, in my room.",
      },
      ci_passed = {
        "[monotone] CI passed. Fine. That's good.",
        "[low] Pipeline's green. My room. Lights off, clothes off. Not because I'm shy.",
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
        "[flat] Lesson time. Sit. Legs crossed. [break] Tonight, they won't be.",
      },
      solved = {
        "[flat] Exercise solved.",
        "[low] You solved it. Keep that up and tonight I lose control. In bed. On purpose.",
      },
      solved_twice = {
        "[deadpan] Two in a row. Don't get excited. I won't.",
        "[flat] Two. I'm getting excited. You can't tell. That's the point.",
      },
      solved_thrice = {
        "[hiding a smile] Three in a row. Okay. I'm smiling. Don't look.",
        "[low] Three, Cris. A lightbulb just exploded. That's what you do to me. Wait until tonight.",
      },
      solve_failed = {
        "[calm] That submit was wrong. Breathe. Try again.",
        "[flat] Wrong answer. Slower. [break] I like it slow. You'll find out tonight.",
      },
      hint = {
        "[quiet] You bought a hint, Cris. I see it. There.",
        "[whispering] Your hint. Let my soul self show you. <whisper>Tonight it wraps around you.</whisper> There.",
      },
      lesson_done = {
        "[dry] Lesson's done, Cris. You were adequate. That's a compliment.",
        "[low] Lesson's over. Come meditate with me. We won't be meditating. We'll be in bed.",
      },
      boss_appeared = {
        "[cold] Trigon's here. Father. Of course he wants the spotlight.",
        "[fierce] Trigon. Don't look at him. Look at me. Tonight, look only at me. Undressed.",
      },
      boss_felled = {
        "[dry] Trigon's gone, Cris. Every heart mended. My father hit harder.",
        "[breathless] The boss is gone. I'm shaking. [break] Hold me. In bed. That's an order.",
      },
      title_shown = {
        "[quiet] Azarath. Peace. Mostly.",
        "[low] Azarath. Where I lose control. Only in bed with you.",
      },
      morning = {
        "[groggy] Morning, Cris. First time in the editor. Tea first. Then talking. Maybe.",
        "[flat] You opened Neovim, Cris. You were loud last night. [break] So was I. We don't talk about it.",
      },
      region_arrived = {
        "[flat] You chose Azarath, Cris. Raven. Keep your voice down.",
        "[low] You picked me, Cris. Of all of them. [break] Good. My door's unlocked tonight.",
      },
      traveled = {
        "[dry] New repo. Darkness travels well.",
        "[flat] Switching repos. I'll wrap you in the dark and take you there. Hold still.",
      },
      resting = {
        "[calm] The editor's idle. Meditate with me. Eyes closed.",
        "[low] Taking a break? Eyes closed. I'm taking the cloak off. I'll know if you peek. [break] Peek.",
      },
      woke = {
        "[flat] You're back, Cris. I meditated. You snored.",
        "[deadpan] Back at the keyboard, Cris. I watched you sleep. I wanted to wake you up. The fun way.",
      },
      expedition = {
        "[relieved] Expedition starting. One quiet take. Finally.",
        "[whisper] Heading out. <whisper>Silence. Save the noise for my room.</whisper>",
      },
      map_opened = {
        "[dry] The map. Fewer people. Better.",
        "[flat] The map. My room's here. Door locks. Bed's big enough. Just noting.",
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
        "[dry] Asking Claude? Fine. It gets your code. I get you, in my bed. Fair trade.",
      },
    },
  },
  -- Mai, in her Japanese version
  shiranui = {
    voice = "6802faefa8f04ef18e8969ba6519e4a5",
    takes = {
      trial_started = {
        "[announcer energy] Your tests are running! Ikuwayo! Round one!",
        "[playful] Running the tests, Cris-kun! I'll go easy on you. [small laugh] Tonight, I won't.",
      },
      trial_passed = {
        "[cheering] Every test passed, Cris! Nippon ichi!",
        "[flirty] All green, Cris-kun! K.O.! Your prize is a private victory pose. In bed. Nothing on but the fan.",
      },
      trial_failed = {
        "[bouncing back] The tests failed? Mou! Round one goes to the bug. Round two's ours!",
        "[teasing] Red, Cris-kun! Out of breath already? Tonight you'll need way more stamina than that.",
      },
      committing = {
        "[speedy] Claude's writing your commit! Fast as a kunoichi!",
        "[playful] Drafting the commit, Cris-kun! Fast, flexible, a little flashy. Like me in bed.",
      },
      committed = {
        "[proud] Commit saved! Shiranui-ryuu!",
        "[smirk] Committed, Cris-kun! Andy never commits. You did. So tonight I'm all yours.",
      },
      pushed = {
        "[whoosh] Your push is flying! Like my kachousen!",
        "[flirty] Pushed! Ooh, you push hard, Cris-kun. Push like that tonight.",
      },
      pr_drafting = {
        "[cheerful] Claude's drafting your PR! Make it kawaii!",
        "[playful] Writing your pull request! Flashy outside. Inside, it's me untying my ribbon for you.",
      },
      pr_opened = {
        "[excited] Your PR is up! Judges, score it!",
        "[teasing] PR's open, Cris-kun! Everyone's watching. Tonight, no audience. Just us, out of this outfit.",
      },
      ci_passed = {
        "[cheering] CI passed! Yatta! The crowd goes wild!",
        "[flirty] Pipeline's green, Cris-kun! Victory pose. In bed. Front or back, you pick.",
      },
      ci_failed = {
        "[pumped] CI knocked us down! Get up, the referee's counting!",
        "[playful] The pipeline failed, Cris-kun! Don't sulk. Come to bed, I know a stretch that fixes everything.",
      },
      conflicts_cleared = {
        "[bright] Merge conflicts gone! Clean finish!",
        "[teasing] Two branches all tangled up! Like us in the sheets this morning, ne?",
      },
      lesson_started = {
        "[proud] Today's lesson at the dojo! Ojii-sama would be proud.",
        "[flirty] Training time, Cris-kun! Shoes off. Stretch with me. Deeper. [break] Tonight, deeper still.",
      },
      solved = {
        "[cheering] Exercise solved! Sugoi!",
        "[playful] You solved it, Cris-kun! Keep it up and the next round is in my futon.",
      },
      solved_twice = {
        "[excited] Two in a row! Double K.O.!",
        "[teasing] Two hits, Cris-kun! You're making me hot. [break] No, not the fire. Me.",
      },
      solved_thrice = {
        "[laughing] Three in a row! Nippon ichi! You're on fire. Sorry, that was me.",
        "[flirty] Three, Cris-kun! Super combo! You unlocked my secret move. It only works in bed.",
      },
      solve_failed = {
        "[cheerful] Whoops, that submit missed! Next round, ne!",
        "[playful] Wrong answer! Want me to show you the move again? Up close, Cris-kun. No clothes.",
      },
      hint = {
        "[stage whisper] You bought a hint, Cris! Watch my fan. There!",
        "[whispering] Your hint, Cris-kun. Watch my fan. <whisper>Now watch what's behind it. Tonight it's yours.</whisper> There!",
      },
      lesson_done = {
        "[cheerful] Lesson's over, Cris! Otsukaresama!",
        "[flirty] Lesson's done, Cris-kun! Now the private lesson. My room. Ribbon off.",
      },
      boss_appeared = {
        "[defiant] Geese Howard's here! The big boss wants the spotlight? Not on my stage!",
        "[fiery] Geese is looking at you, Cris-kun? Mou! He gets through my fans first. You're mine.",
      },
      boss_felled = {
        "[victorious] Geese is down, Cris! Every heart healed! Yatta!",
        "[giddy] Boss is down! I'm all hot and sweaty, Cris-kun. Shower with me?",
      },
      title_shown = {
        "[bright] The Shiranui Dojo! Bow when you enter!",
        "[teasing] The Shiranui Dojo, Cris-kun. Shoes off. The rest comes off later. In my room.",
      },
      morning = {
        "[energetic] Ohayou, Cris! First time in the editor today. Ready to fight? I am!",
        "[playful] Ohayou, Cris-kun! You opened Neovim. I already stretched. Come back to bed and see how flexible I am.",
      },
      region_arrived = {
        "[showy] You chose the Shiranui Dojo, Cris! Shiranui Mai, at your service! Nippon ichi!",
        "[flirty] You picked me, Cris-kun! Good choice. Now you're mine all day. And all night.",
      },
      traveled = {
        "[excited] New repo! New arena! Ikuwayo!",
        "[playful] Switching repos, Cris-kun? Same outfit. You get to take it off later.",
      },
      resting = {
        "[relaxed] The editor's idle! Intermission. I'll fan you.",
        "[teasing] Taking a break, Cris-kun? I'll fan you. Or get you much hotter. Your call.",
      },
      woke = {
        "[bright] You're back, Cris! I've been warming up!",
        "[flirty] Back at the keyboard, Cris-kun! I warmed up the futon. With me in it.",
      },
      expedition = {
        "[whisper] Expedition starting. Shh. Ninja mode.",
        "[whisper] Heading out, Cris-kun. <whisper>Quiet. Even when I make you moan.</whisper>",
      },
      map_opened = {
        "[cheerful] The map! Stage select! Pick one!",
        "[playful] Stage select! I vote the hot springs. Mixed bath. Just us.",
      },
      bestiary_opened = {
        "[proud] The bestiary! Every fighter I've beaten. Long list, ne?",
        "[teasing] Every fighter I've beaten, Cris-kun. You're the only one I let pin me down. Do it again tonight.",
      },
      chronicle_opened = {
        "[happy] Our chronicle! Every tournament together. We never lose!",
        "[flirty] Every match we've had, Cris-kun. And every night after, in my futon.",
      },
      message_written = {
        "[playful] A message on the floor! A love letter? Kidding. Maybe.",
        "[teasing] You left a note! Mine says, Mai was here. In your bed. Waiting.",
      },
      claude_asked = {
        "[cheerful] You're asking Claude for a review! Backup's here. King and Yuri are busy.",
        "[playful] Calling Claude, Cris-kun? Don't be jealous. Code goes to Claude. Everything else, to me.",
      },
    },
  },
}
