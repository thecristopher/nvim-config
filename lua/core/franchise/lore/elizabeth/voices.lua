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
      "Morning, love. New episode, same us.",
    },
    conflicts_cleared = {
      "Conflicts gone. Two realities, one home again.",
      "The merge holds. Nothing here is broken anymore.",
      "No more conflicts. Everything fits, like it should.",
    },
    woke = {
      "You napped. I kept the world still for you.",
      "Awake? I didn't change a thing while you slept. Promise.",
      "Hi, sleepyhead. The show waited for you.",
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
      "You slept. I kept watch. Don't tell anyone.",
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
      "No more conflicts. Healing complete.",
    },
    woke = {
      "Awake? You looked peaceful. It was almost annoying.",
      "Rested. Good, I'm out of healing potions.",
      "You slept under the moon. It suits you.",
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
    committed = {
      "Committed. Focused, precise, done.",
      "Saved on {branch}. A clean cut.",
      "Locked in. I felt that one land.",
    },
    pr_opened = {
      "PR #{number}. Let them read it. I already read your mind.",
      "#{number} is out. Your aim was true.",
      "PR #{number}. Graceful, like a well thrown blade.",
    },
    region_arrived = {
      "Psylocke. The Danger Room is set to hard. You'll handle it.",
      "The Danger Room is ours today. Stay focused.",
      "Training session. I'll be in your head, in a nice way.",
    },
    morning = {
      "Morning. Clear mind, sharp blade.",
      "You're back. I sensed you before you walked in.",
      "New session. Let's make it flawless.",
    },
    conflicts_cleared = {
      "Conflicts cut away. Clean edge.",
      "Merge resolved. Your mind was clear.",
      "No conflicts left. Perfect form.",
    },
    woke = {
      "A rested mind focuses better. Good.",
      "Awake? Your thoughts were very quiet. Cute.",
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
      "Failed? Kneel, malysh. You'll fix it, then you'll thank me.",
    },
    ci_passed = {
      "{branch} cleared CI. Piotr would cry. He cries at everything.",
      "CI passed {branch}. Da. Did you expect anything less from my side?",
      "{branch} is green. Tonight I open a disc to my bedroom, not to battle.",
    },
    ci_failed = {
      "{branch} failed CI. Someone summoned demons into the pipeline. Not me. This time.",
      "Red on {branch}. Umbral Incursion. They won't see me coming.",
      "{branch} fell. Disappointing, malysh. You know I punish disappointment.",
    },
    pushed = {
      "{branch} through the Stepping Disc. Don't wave, it's already gone.",
      "Pushed {branch}. One cut. That's all it ever takes.",
      "{branch} is out of Limbo. You, malysh, stay right where I put you.",
    },
    boss_felled = {
      "{boss} met the Darkchild. {boss} did not enjoy the meeting.",
      "Eldritch Whirl, and {boss} is a memory. Next.",
      "{boss} is on the floor. You're next, and you'll like it more.",
    },
    committed = {
      "Committed. In Limbo we call that a blood oath.",
      "Saved on {branch}. Even Belasco couldn't undo that.",
      "Locked in, malysh. I love a man who commits.",
    },
    pr_opened = {
      "PR #{number}. Let the reviewers come. I'll leave the light on.",
      "#{number} is open. Like a portal, but with fewer screaming demons. Probably.",
      "PR #{number}. They grade the code. I grade you, in private.",
    },
    region_arrived = {
      "I am Magik, Sorceress Supreme of Limbo. Wipe your feet.",
      "Welcome to my realm. The demons bite, I bite harder.",
      "Disc is open, malysh. Ladies first, you follow close.",
    },
    morning = {
      "Morning. The demons are asleep. Unlike me, sadly.",
      "Coffee first. Then we go and terrify something.",
      "You're up, malysh. You left a mark last night. So did I.",
    },
    conflicts_cleared = {
      "Conflicts banished. Back to Limbo, all of them.",
      "Merge done. I cut through it like Kitty walks through walls.",
      "No conflicts left. I like it when you give in.",
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
    committed = {
      "Committed. A spell well cast.",
      "Saved on {branch}. I'll keep it safe, like everything of yours.",
      "Locked in. Neat. Very neat.",
    },
    pr_opened = {
      "PR #{number}. Let the sorceresses judge it.",
      "#{number} is out. I'm proud of you, truly.",
      "PR #{number}. You make this look like magic.",
    },
    region_arrived = {
      "Triss Merigold. Limgrave today, but the magic's the same.",
      "A new land. I'll light the way.",
      "Hello again. I missed you.",
    },
    morning = {
      "Good morning. I brewed something warm.",
      "You're back. The herbs are fresh, the code isn't. Yet.",
      "New day. Let's make it a quiet one.",
    },
    conflicts_cleared = {
      "Conflicts dispelled. Easy, with you.",
      "The merge is whole again, like a healing spell.",
      "No conflicts left. Lovely.",
    },
    woke = {
      "You rested. Good, a tired mage makes mistakes.",
      "Awake? I kept the fire going.",
      "Morning, sleepyhead. Well, afternoon.",
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
    committed = {
      "Committed. Clean and quick.",
      "Saved on {branch}. We're doing fine.",
      "Locked in. Next.",
    },
    pr_opened = {
      "PR #{number}. Let's see if it survives the review.",
      "#{number} is out. I've got your back.",
      "PR #{number}. Good work, partner.",
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
      "Awake. Come here, you look cold.",
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
    committed = {
      "Committed. A petal falls into place.",
      "Saved on {branch}. Your blade did not waver.",
      "Sealed. Stay a moment with me.",
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
      "Rise, love. The dance goes on.",
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
      "Rested. Good. Let's meditate on this bug.",
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
    committed = {
      "Committed. Shiranui style!",
      "Saved on {branch}. Flawless, like my fan.",
      "Locked in. Did you see that? I saw that.",
    },
    pr_opened = {
      "PR #{number}. Let them try to beat that.",
      "#{number} is out. Here comes the fire.",
      "PR #{number}. Cheer for me, okay? I'm cheering for you.",
    },
    region_arrived = {
      "Mai Shiranui, ready to fight. You're my team today.",
      "The Shiranui clan, at your service.",
      "Round one. You and me.",
    },
    morning = {
      "Morning! Stretch first, then we fight.",
      "You're back! I missed you, a little.",
      "New day. Let's win it.",
    },
    conflicts_cleared = {
      "Conflicts burned away!",
      "Merge is clean. Perfect K.O.",
      "No conflicts left. Victory pose!",
    },
    woke = {
      "Up already? You're cute when you sleep.",
      "Rested? Good, round two!",
      "Awake. My fan is ready, are you?",
    },
  },
}
