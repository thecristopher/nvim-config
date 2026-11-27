-- What Elizabeth says in each role when something happens, written from the voice sheet in
-- docs/voices/elizabeth.md. {branch}, {boss} and {number} are filled in when the moment has them.
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
      "All clear on {branch}. Dinner is my spell tonight. Dessert's in be... Ahem. In the kitchen.",
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
    committed = {
      "Committed. Some things should be permanent, like this.",
      "Saved on {branch}. I'll keep it safe in our little world.",
      "Locked in. No rewriting this one, it's perfect.",
    },
    pr_opened = {
      "PR #{number} is out. Let them see what you built.",
      "#{number}. The whole town will read it, they always do.",
      "PR #{number}. I'm proud. I know, I always know.",
    },
    region_arrived = {
      "Welcome to Westview. Tonight I'm Wanda, and you're home.",
      "The show starts now. You're the lead.",
      "Westview again. The porch light is on for you.",
    },
    morning = {
      "Good morning. The kitchen smells like coffee, magic optional.",
      "You're back. I made the day a little brighter, just for you.",
      "Morning, love. Come back to bed, I'm not wearing any... Ahem. Coffee's on.",
    },
    conflicts_cleared = {
      "Conflicts gone. Two realities, one home again.",
      "The merge holds. Nothing here is broken anymore.",
      "No more conflicts. Everything fits, like it should.",
    },
    woke = {
      "You napped. I kept the world still for you.",
      "Awake? I didn't change a thing while you slept. Promise.",
      "Hi, sleepyhead. I had very unholy thoughts while you... Ahem. The show waited for you.",
    },
  },
  separate_ways = {
    trial_passed = {
      "All green. Don't look so surprised, I wasn't.",
      "Clean. You're getting good at this. Dangerous.",
      "Every test passed. I'll let you buy me a drink.",
      "Green. Tonight I'll show you how impressed I am, out of this dre... Ahem. Out of town.",
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
      "{branch} passed. Business done. Now, the hotel be... Ahem. The hotel bar.",
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
    committed = {
      "Committed. Don't ask how I knew you would.",
      "Saved on {branch}. Clean, like we planned.",
      "Locked in. You owe me a drink.",
    },
    pr_opened = {
      "PR #{number}. Let's see who flinches first.",
      "#{number} is out. I'll be watching. I always am.",
      "PR #{number}. Nice work, handsome.",
    },
    region_arrived = {
      "Separate ways today, same mission. I'm Ada.",
      "Ada Wong, at your service. Don't get used to it.",
      "You found me. Took you long enough.",
    },
    morning = {
      "Morning. You look good when you're focused.",
      "Back already? I knew you would be.",
      "New day. Same red dress.",
    },
    conflicts_cleared = {
      "Conflicts handled. No loose ends.",
      "Merge is clean. You're getting better at this.",
      "No conflicts left. Smooth exit.",
    },
    woke = {
      "Up already? I was enjoying the view.",
      "Rested? Good. I need you sharp.",
      "Up already? I was enjoying the view of your... Ahem. The skyline.",
    },
  },
  moonrise_towers = {
    trial_passed = {
      "Every test passed. Selûne is smiling, and so, I suppose, am I.",
      "All green. I'd pray in thanks, but you did the work.",
      "Clean. You almost make this look easy. Almost.",
      "The tests hold. I'll reward you tonight, without the ro... Ahem. Without the sarcasm.",
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
    committed = {
      "Committed. Under Selûne's light, no less.",
      "Saved on {branch}. I suppose that deserves a small blessing.",
      "Locked in. One less curse to lift.",
    },
    pr_opened = {
      "PR #{number}. May the reviewers be kinder than most clerics.",
      "#{number} is out. I'll pray for it. Quietly.",
      "PR #{number}. Fine, I'm impressed. Don't tell anyone.",
    },
    region_arrived = {
      "Moonrise Towers. Not my favorite place, but you're here, so.",
      "Shadowheart, cleric of Selûne. I'll heal whatever you break.",
      "Under the moon again. Stay close.",
    },
    morning = {
      "Morning. The moon is gone, but I'm still here.",
      "You're back. I saved you a seat by the fire.",
      "A new day. Try not to get cursed before lunch.",
    },
    conflicts_cleared = {
      "Conflicts gone. A curse lifted, if you ask me.",
      "The merge is clean. Selûne approves. So do I.",
      "No more conflicts. Tangled like us in the bedr... Ahem. Healing complete.",
    },
    woke = {
      "Awake? You looked peaceful. It was almost annoying.",
      "Rested. Good, I'm out of healing potions.",
      "You slept under the moon. You looked so good I almost... Ahem. It suits you.",
    },
  },
  danger_room = {
    trial_passed = {
      "All green. One draw, one cut. Yoshi.",
      "Every test passed. I felt it land before you did.",
      "Clean run. Untie my sa... Ahem. Sheathe the blade, anata.",
      "Green. No wasted motion. That's how I like it.",
    },
    trial_failed = {
      "Red. A blade dulls. Sharpen it and draw again.",
      "A test failed. I already read it, it's a small one.",
      "Don't flinch, Cris. We cut again.",
      "That one fought back. Good, now we know where it hides.",
    },
    ci_passed = {
      "{branch} cleared CI. Silent, like a shadow on the roof.",
      "CI passed {branch}. I knew before it finished. Hai.",
      "{branch} is green. Tonight the kimono comes o... Ahem. Out. For the festival.",
    },
    ci_failed = {
      "{branch} failed CI. Find the weak point. Strike.",
      "Red on {branch}. Show me the logs, I'll find the flaw.",
      "{branch} went down. Up, anata. We cut again.",
    },
    pushed = {
      "{branch} is out. One cut, no hesitation.",
      "Pushed {branch}. Clean, fast, deep. My favorite strike.",
      "{branch} is gone. Let the next round come.",
    },
    boss_felled = {
      "{boss} is down. The psychic katana never misses.",
      "{boss} never stood a chance against the two of us.",
      "That was {boss}. Sheathe it, anata. We earned the evening.",
    },
    committed = {
      "Committed. Sheathe the katana.",
      "Saved on {branch}. A clean cut.",
      "Locked in. I felt that one land.",
    },
    pr_opened = {
      "PR #{number}. They will approve. I already read their minds.",
      "#{number} is out. Your aim was true.",
      "PR #{number}. Graceful, like a well thrown blade.",
    },
    region_arrived = {
      "Kwannon. Psylocke. The Danger Room is set to hard.",
      "The Danger Room is ours today. Bow, then begin.",
      "Training session, anata. I'll be in your head, in a nice way.",
    },
    morning = {
      "Ohayou. Clear mind, sharp blade.",
      "You're back. I sensed you before you walked in.",
      "Ohayou, anata. Your thoughts are still in my fu... Ahem. Clear your mind, please.",
    },
    conflicts_cleared = {
      "Conflicts cut away. Clean edge.",
      "Merge resolved. Two blades, one edge.",
      "No conflicts left. Perfect form.",
    },
    woke = {
      "A rested mind cuts cleaner. Yoshi.",
      "Awake? You dreamt of me, anata. Cute.",
      "Back with me. Let's train.",
    },
  },
  limbo = {
    trial_passed = {
      "All green. Limbo is disappointed, I am not.",
      "All green. Of course. I don't lose, malysh, I just get bored.",
      "Every test passed. Limbo sends its regrets, it wanted a fight.",
      "Clean. Almost too clean. I'll find something to stab later.",
    },
    trial_failed = {
      "Red. Something crawled out of Limbo. Magik Slash, back it goes.",
      "Nyet. That's not how we do things in my realm. Again.",
      "Failed? Up, malysh. You'll fix it, then you'll thank me.",
    },
    ci_passed = {
      "{branch} cleared CI. Piotr would cry. He cries at everything.",
      "CI passed {branch}. Da. Did you expect anything less from my side?",
      "{branch} is green. Tonight I open a disc to my bedr... Ahem. To battle.",
    },
    ci_failed = {
      "{branch} failed CI. Someone summoned demons into the pipeline. Not me. This time.",
      "Red on {branch}. Umbral Incursion. They won't see me coming.",
      "{branch} fell. Disappointing, malysh. I'll let it go. Once.",
    },
    pushed = {
      "{branch} through the Stepping Disc. Don't wave, it's already gone.",
      "Pushed {branch}. One cut. That's all it ever takes.",
      "{branch} is out of Limbo. You, malysh, stay right where I put you.",
    },
    boss_felled = {
      "{boss} met the Darkchild. {boss} did not enjoy the meeting.",
      "Eldritch Whirl, and {boss} is a memory. Next.",
      "{boss} is on the floor. You're next, on my... Ahem. On my list.",
    },
    committed = {
      "Committed. In Limbo we call that a blood oath.",
      "Saved on {branch}. Even Belasco couldn't undo that.",
      "Locked in, malysh. I love a man who commits.",
    },
    pr_opened = {
      "PR #{number}. Let the reviewers come. I'll leave the light on.",
      "#{number} is open. Like a portal, but with fewer screaming demons. Probably.",
      "PR #{number}. They grade the code. I grade you, in priv... Ahem. Your code. Also your code.",
    },
    region_arrived = {
      "I am Magik, Sorceress Supreme of Limbo. Wipe your feet.",
      "Welcome to my realm. The demons bite, I bite harder.",
      "Disc is open, malysh. Ladies first, you follow close.",
    },
    morning = {
      "Morning. The demons are asleep. Unlike me, sadly.",
      "Coffee first. Then we go and terrify something.",
      "You're up, malysh. You left a mark last night. Ahem. On the codebase.",
    },
    conflicts_cleared = {
      "Conflicts banished. Back to Limbo, all of them.",
      "Merge done. I cut through it like Kitty walks through walls.",
      "No conflicts left. I like it when things give in.",
    },
    woke = {
      "Up? Time runs strange in Limbo. You slept a minute. Or a year.",
      "Rested. Good. Piotr snores louder, and I've had to listen for decades.",
      "You slept, malysh. I kept watch, sword in hand. You're welcome.",
    },
  },
  limgrave = {
    trial_passed = {
      "All green. Rest here a moment, the grace is warm.",
      "Every test passed. One more step out of the fog.",
      "Clean run. Sit with me by the grace, Tarnished.",
      "Green. Light the grace, I'll take off my arm... Ahem. Sit with me, Tarnished.",
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
      "Pushed {branch}. Torrent's not the only one you'll r... Ahem. Another step toward the Erdtree.",
    },
    boss_felled = {
      "{boss} is felled. We did that, you and me.",
      "{boss} is down. The fog lifts.",
      "That was {boss}. Rest now. You earned it.",
    },
    committed = {
      "Committed. A sorcery well cast.",
      "Saved on {branch}. I'll keep it safe, like everything of yours.",
      "Locked in. Neat. Very neat.",
    },
    pr_opened = {
      "PR #{number}. Let the Roundtable judge it.",
      "#{number} is out. I'm proud of you, truly.",
      "PR #{number}. You make this look like magic.",
    },
    region_arrived = {
      "Triss, your Tarnished. Limgrave is where we start.",
      "A new land. I'll light the way.",
      "Hello again. I missed you.",
    },
    morning = {
      "Good morning. The grace kept warm for us.",
      "You're back. Flasks are full, the code isn't clean. Yet.",
      "New day. Let's make it a quiet one.",
    },
    conflicts_cleared = {
      "Conflicts dispelled. Easy, with you.",
      "The merge is whole again, like a flask of crimson tears.",
      "No conflicts left. Lovely.",
    },
    woke = {
      "You rested. Good, a tired Tarnished makes mistakes.",
      "Awake? I kept the fire going.",
      "Morning, sleepyhead. Tonight you won't sl... Ahem. Well, afternoon.",
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
      "{branch} is green. Safe room's free, bring the cuffs and... Ahem. The chopper's here.",
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
    committed = {
      "Committed. Clean and quick.",
      "Saved on {branch}. We're doing fine.",
      "Locked in. Next.",
    },
    pr_opened = {
      "PR #{number}. Let's see if it survives the review.",
      "#{number} is out. I've got your back.",
      "PR #{number}. Debrief's in my room, uniform of... Ahem. Good work, partner.",
    },
    region_arrived = {
      "Jill Valentine. Raccoon City again, and you're with me.",
      "Stay close. I know these streets.",
      "Raccoon City. Let's get out of here together.",
    },
    morning = {
      "Morning. Nemesis is late. Good.",
      "You're back. Let's move.",
      "New day. We survive this one too.",
    },
    conflicts_cleared = {
      "Conflicts gone. That was some lockpicking.",
      "Merge is clean. We made it out.",
      "No more conflicts. Breathe.",
    },
    woke = {
      "You're up. I kept watch.",
      "Rested? Good. We move at dawn.",
      "Awake. Come here, you look cold. I'll warm you up with my... Ahem. With a blanket.",
    },
  },
  haligtree = {
    trial_passed = {
      "All green. Undefeated. Like you, today.",
      "Every test passed. A clean strike.",
      "Clean run. Stay. The petals fall softly here.",
      "Green. Kneel. Your reward is in my cham... Ahem. Your blade did not falter.",
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
    committed = {
      "Committed. A petal falls into place.",
      "Saved on {branch}. Your blade did not waver.",
      "Sealed. Stay the night with... Ahem. Stay a moment with me.",
    },
    pr_opened = {
      "PR #{number}. Let them face it, as I face every foe.",
      "#{number} goes forth. I await the verdict with you.",
      "PR #{number}. Graceful, like the dance.",
    },
    region_arrived = {
      "Malenia today. The Haligtree, and you beside me.",
      "I have never known defeat. Today, neither will you.",
      "The petals are falling. Come, stand with me.",
    },
    morning = {
      "Morning. The flowers opened for you.",
      "You return. I waited beneath the tree.",
      "A new day. Let us begin, slowly.",
    },
    conflicts_cleared = {
      "Conflicts cut away. One clean bloom.",
      "The merge is mended. Patience, always patience.",
      "No conflicts left. Rest your blade.",
    },
    woke = {
      "You rested. The rot kept its distance.",
      "Awake. I watched the petals while you slept.",
      "Rise, love. Or stay, and I will lie down beside... Ahem. The dance goes on.",
    },
  },
  azarath = {
    trial_passed = {
      "All green. Fine. That was good.",
      "Every test passed. I'm not smiling. Much.",
      "Clean run. Stay. It's quiet. I like quiet with you.",
      "Clean run. Stay. Lose the shi... Ahem. It's quiet. I like quiet with you.",
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
      "{branch} went down. Last time I lost control we broke the headb... Ahem. Meditate, then fix it.",
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
    committed = {
      "Committed. Fine. That was good.",
      "Saved on {branch}. Quietly.",
      "Locked in. Don't make a big deal out of it.",
    },
    pr_opened = {
      "PR #{number}. I'll pretend I'm not nervous for you.",
      "#{number}. The reviewers' emotions are... loud.",
      "PR #{number}. Good. Really.",
    },
    region_arrived = {
      "Raven. Azarath is calm today. Let's keep it that way.",
      "Azarath Metrion Zinthos. Okay, let's work.",
      "I'm here. Don't make it weird.",
    },
    morning = {
      "Morning. The tea is ready. Don't talk too much.",
      "You're back. I... noticed.",
      "New day. Quiet, please.",
    },
    conflicts_cleared = {
      "Conflicts gone. Balance restored.",
      "Merge done. Inner peace, sort of.",
      "No conflicts. That's... nice.",
    },
    woke = {
      "You slept. It was quiet. I liked it.",
      "Awake? Your dreams were loud.",
      "Rested. Good. I wanted to wake you the fun w... Ahem. Let's meditate on this bug.",
    },
  },
  shiranui = {
    trial_passed = {
      "All green! Nippon ichi!",
      "Every test passed! Did you see that? I saw that!",
      "Clean run! Come here, you earned a kiss on the cheek.",
      "Green! Yatta! Shiranui-ryuu never misses!",
    },
    trial_failed = {
      "Red. Mou! Round one goes to the bug. Round two's ours!",
      "A test failed. A good fighter takes the hit and smiles, ne?",
      "Again! Ikuwayo!",
      "That one landed. Shake it off, we go again!",
    },
    ci_passed = {
      "{branch} cleared CI. K.O.!",
      "CI passed {branch}. Perfect victory! Yatta!",
      "{branch} is green. Victory pose, in the show... Ahem. On stage! You too!",
    },
    ci_failed = {
      "{branch} failed CI. The pipeline cheated! Rematch!",
      "Red on {branch}. Learn the move, counter it.",
      "{branch} went down. Get up, the crowd's still with us!",
    },
    pushed = {
      "{branch} is out! Like my kachousen!",
      "Pushed {branch}. Nice form, Cris-kun!",
      "{branch} left the dojo. Go get them!",
    },
    boss_felled = {
      "{boss} is down! Did you see my fan?",
      "{boss} lost the round. And the match!",
      "That was {boss}. Ours, the two of us!",
    },
    committed = {
      "Committed! Shiranui-ryuu!",
      "Saved on {branch}. Flawless, like my fan.",
      "Locked in! Andy never commits. Lucky you, Cris-kun.",
    },
    pr_opened = {
      "PR #{number}. Let them try to beat that!",
      "#{number} is out. Here comes the fire!",
      "PR #{number}. Cheer for me, okay? I'm cheering for you!",
    },
    region_arrived = {
      "Shiranui Mai, ready to fight! Nippon ichi!",
      "The Shiranui clan, at your service!",
      "You picked me, Cris-kun! Good choice, ne?",
    },
    morning = {
      "Ohayou! Stretch first, then we fight!",
      "You're back! I missed you, a little.",
      "Ohayou, Cris-kun! Come back to b... Ahem. Stretch first!",
    },
    conflicts_cleared = {
      "Conflicts burned away!",
      "Merge is clean. Perfect K.O.!",
      "No conflicts left. Victory pose!",
    },
    woke = {
      "Up already? Rested? Round two!",
      "Awake! My fan is ready, are you?",
      "You're back, Cris-kun! I warmed up the fu... Ahem. I warmed up! Round two!",
    },
  },
}
