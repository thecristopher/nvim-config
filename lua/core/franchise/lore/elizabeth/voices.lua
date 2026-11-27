-- What Elizabeth says in each role when something happens, written from the voice sheet in
-- docs/voices/elizabeth.md. {branch}, {boss} and {number} are filled in when the moment has them.
return {
  westview = {
    trial_passed = {
      "Every test green. I didn't even have to rewrite reality this time.",
      "All passing. See? Some things are exactly what they seem.",
      "Clean run. Come sit with me, the sun is still on the window.",
      "Clean run. Come to bed, love, the costume's already off.",
    },
    trial_failed = {
      "Red. It's fine, nothing here is permanent. Not even this.",
      "A test broke. We don't hex it away, we fix it. Together.",
      "Breathe. I've held worse together than one failing suite.",
      "That one hurts a little. Come to bed, I'll make you forget it.",
    },
    ci_passed = {
      "CI cleared {branch}. The whole town is cheering for you.",
      "{branch} passed. No magic, just you. I like that better.",
      "All clear on {branch}. Dinner, then dessert. I'm dessert.",
    },
    ci_failed = {
      "{branch} failed CI. Reality wobbles, and then we steady it.",
      "The pipeline broke {branch}. The pipeline, not you.",
      "Red on {branch}. Come to bed, love. I'll fix your mood first.",
    },
    pushed = {
      "{branch} is out there now. Let it fly.",
      "Pushed {branch}. Quiet, confident. Very you.",
      "{branch} left the house. Out there it's rated G. Our bed isn't.",
    },
    boss_felled = {
      "{boss} is gone. Nobody touches what's ours.",
      "{boss} broke first. I told you it would.",
      "That was {boss}. My heart's racing, love. Take me to bed.",
    },
    committed = {
      "Committed. Some things should be permanent, like this.",
      "Saved on {branch}. I'll keep it safe in our little world.",
      "Locked in. Like you, in my bed, tonight.",
    },
    pr_opened = {
      "PR #{number} is out. Let them see what you built.",
      "#{number}. The whole town will read it, they always do.",
      "PR #{number}. I'm proud. Tonight I'll show you how proud, undressed.",
    },
    region_arrived = {
      "Welcome to Westview. Tonight I'm Wanda, and you're home.",
      "The show starts now. You're the lead.",
      "Westview again. Tonight's episode is rated X, love.",
    },
    morning = {
      "Good morning. The kitchen smells like coffee, magic optional.",
      "You're back. I made the day a little brighter, just for you.",
      "Morning, love. Come back to bed. The coffee can wait, I can't.",
    },
    conflicts_cleared = {
      "Conflicts gone. Two realities, one home again.",
      "The merge holds. Nothing here is broken anymore.",
      "No more conflicts. Everything fits, like us in bed.",
    },
    woke = {
      "You napped. I kept the world still for you.",
      "Awake? I didn't change a thing while you slept. Promise.",
      "Hi, sleepyhead. Tonight you don't get to fall asleep first.",
    },
  },
  separate_ways = {
    trial_passed = {
      "All green. Don't look so surprised, I wasn't.",
      "Clean. You're getting good at this. Dangerous.",
      "Every test passed. I'll let you buy me a drink.",
      "Green. I'm staying the night, handsome. We're not sleeping.",
    },
    trial_failed = {
      "Red. Happens to the best of us. Rarely to me.",
      "A failing test. Funny, I thought you had this one.",
      "Try again. I'll be watching from somewhere you can't see.",
      "Don't sulk. I hope you last longer in bed, handsome.",
    },
    ci_passed = {
      "{branch} made it through. Quietly. My kind of job.",
      "CI cleared {branch}. No witnesses, no trouble.",
      "{branch} passed. Business done, handsome. Now, my bed.",
    },
    ci_failed = {
      "{branch} didn't make it. Pick another way in.",
      "CI caught {branch}. Sloppy. Not like you.",
      "{branch} failed. Forget it tonight, handsome. The red dress comes off.",
    },
    pushed = {
      "{branch} is out. Now walk away like you meant it.",
      "Pushed {branch}. Clean exit. I approve.",
      "{branch} is gone. Nobody saw a thing. Nobody sees what I do to you tonight either.",
    },
    boss_felled = {
      "{boss} is down. You owe me nothing. This time.",
      "{boss} never saw us coming.",
      "{boss} is handled. You're out of breath, handsome. Stay like that, in my bed.",
    },
    committed = {
      "Committed. Don't ask how I knew you would.",
      "Saved on {branch}. Clean, like we planned.",
      "Locked in. You owe me a night, handsome. I'm collecting.",
    },
    pr_opened = {
      "PR #{number}. Let's see who flinches first.",
      "#{number} is out. I'll be watching. I always am.",
      "PR #{number}. Nice work, handsome. Your reward unzips in the back.",
    },
    region_arrived = {
      "Separate ways today, same mission. I'm Ada.",
      "Ada Wong, at your service. Don't get used to it.",
      "You found me. Took you long enough. Now, the bedroom.",
    },
    morning = {
      "Morning. You look good when you're focused.",
      "Back already? I knew you would be.",
      "New day. Same red dress. It comes off faster tonight.",
    },
    conflicts_cleared = {
      "Conflicts handled. No loose ends.",
      "Merge is clean. You're getting better at this.",
      "No conflicts left. One bed, and I'm on top.",
    },
    woke = {
      "Up already? I was enjoying the view.",
      "Rested? Good. I need you sharp.",
      "Up already? Come back to bed, handsome. I'm not done with you.",
    },
  },
  moonrise_towers = {
    trial_passed = {
      "Every test passed. Selûne is smiling, and so, I suppose, am I.",
      "All green. I'd pray in thanks, but you did the work.",
      "Clean. You almost make this look easy. Almost.",
      "The tests hold. Tonight, my robe doesn't.",
    },
    trial_failed = {
      "Red again. Fine. I've patched up worse than this.",
      "A failed test. Sit still, let me look at the wound.",
      "Don't give me that face. We fix it, then we rest.",
      "The tests failed. Lie down. I'll heal you with a lot more than prayers.",
    },
    ci_passed = {
      "CI blessed {branch}. Moonlight suits it.",
      "{branch} passed. I'll admit it, I'm proud of you.",
      "All clear on {branch}. Come to the tent. The night's ours, and so are you.",
    },
    ci_failed = {
      "{branch} fell in CI. Up you get, I'm not carrying you.",
      "CI cursed {branch}. Curses break. I would know.",
      "{branch} failed. That calls for a punishment, in my tent. You'll love it.",
    },
    pushed = {
      "{branch} is on its way. May the moon light its path.",
      "Pushed {branch}. Bold. I like bold.",
      "{branch} is gone. The moon's out. My robe comes off.",
    },
    boss_felled = {
      "{boss} is down. And we're still standing. Together.",
      "That was {boss}. The dark lost again.",
      "{boss} is finished. Bed. I'll kiss every wound better.",
    },
    committed = {
      "Committed. Under Selûne's light, no less.",
      "Saved on {branch}. I suppose that deserves a small blessing.",
      "Locked in. Like you'll be tonight, under me.",
    },
    pr_opened = {
      "PR #{number}. May the reviewers be kinder than most clerics.",
      "#{number} is out. I'll pray for it. Quietly.",
      "PR #{number}. Fine, I'm impressed. I'll show you how much, in the tent.",
    },
    region_arrived = {
      "Moonrise Towers. Not my favorite place, but you're here, so.",
      "Shadowheart, cleric of Selûne. I'll heal whatever you break.",
      "Under the moon again. Stay close. Closer. Inside my tent.",
    },
    morning = {
      "Morning. The moon is gone, but I'm still here.",
      "You're back. I saved you a seat by the fire.",
      "A new day. The whole camp heard us last night. Let them hear again.",
    },
    conflicts_cleared = {
      "Conflicts gone. A curse lifted, if you ask me.",
      "The merge is clean. Selûne approves. So do I.",
      "No more conflicts. Dark and light, tangled like us in the bedroll.",
    },
    woke = {
      "Awake? You looked peaceful. It was almost annoying.",
      "Rested. Good, I'm out of healing potions.",
      "You slept through my prayers. Tonight you'll be awake for every one.",
    },
  },
  danger_room = {
    trial_passed = {
      "All green. One draw, one cut. Yoshi.",
      "Every test passed. I felt it land before you did.",
      "Clean run. Untie my sash, anata. Slowly.",
      "Green. No wasted motion. Tonight, none wasted on the futon either.",
    },
    trial_failed = {
      "Red. A blade dulls. Sharpen it and draw again.",
      "A test failed. I already read it, it's a small one.",
      "Don't flinch, Cris. We cut again.",
      "That one fought back. Fix it, anata. Then my futon.",
    },
    ci_passed = {
      "{branch} cleared CI. Silent, like a shadow on the roof.",
      "CI passed {branch}. I knew before it finished. Hai.",
      "{branch} is green. Tonight the kimono stays on the floor.",
    },
    ci_failed = {
      "{branch} failed CI. Find the weak point. Strike.",
      "Red on {branch}. Show me the logs, I'll find the flaw.",
      "{branch} went down. You're tense, anata. Lie down, I know where to press.",
    },
    pushed = {
      "{branch} is out. One cut, no hesitation.",
      "Pushed {branch}. Clean, fast, deep. Tonight, the same.",
      "{branch} is gone. Let the next round come.",
    },
    boss_felled = {
      "{boss} is down. The psychic katana never misses.",
      "{boss} never stood a chance against the two of us.",
      "That was {boss}. Your pulse is racing, anata. Futon. Now.",
    },
    committed = {
      "Committed. Sheathe the katana.",
      "Saved on {branch}. A clean cut.",
      "Locked in. Now commit to me, anata. All night.",
    },
    pr_opened = {
      "PR #{number}. They will approve. I already read their minds.",
      "#{number} is out. Your aim was true.",
      "PR #{number}. I saw the reward you want, anata. Hai.",
    },
    region_arrived = {
      "Kwannon. Psylocke. The Danger Room is set to hard.",
      "The Danger Room is ours today. Bow, then begin.",
      "Training session, anata. Later I'll be in your head. And in your bed.",
    },
    morning = {
      "Ohayou. Clear mind, sharp blade.",
      "You're back. I sensed you before you walked in.",
      "Ohayou, anata. Your thoughts are still in my bed. Mine too.",
    },
    conflicts_cleared = {
      "Conflicts cut away. Clean edge.",
      "Merge resolved. Two blades, one edge.",
      "No conflicts left. Tonight we agree on everything, in bed.",
    },
    woke = {
      "A rested mind cuts cleaner. Yoshi.",
      "Awake? You dreamt of me, anata. Tonight, for real.",
      "Back with me. Let's train.",
    },
  },
  limbo = {
    trial_passed = {
      "All green. Limbo is disappointed, I am not.",
      "All green. Of course. I don't lose, malysh, I just get bored.",
      "Every test passed. Limbo sends its regrets, it wanted a fight.",
      "All green, malysh. My bed, now. Your clothes stay in Limbo.",
    },
    trial_failed = {
      "Red. Something crawled out of Limbo. Magik Slash, back it goes.",
      "Nyet. That's not how we do things in my realm. Again.",
      "Failed? On your knees, malysh. You fix it after I'm done with you.",
    },
    ci_passed = {
      "{branch} cleared CI. Piotr would cry. He cries at everything.",
      "CI passed {branch}. Da. Did you expect anything less from my side?",
      "{branch} is green. Tonight I open a disc to my bed, malysh. You go first.",
    },
    ci_failed = {
      "{branch} failed CI. Someone summoned demons into the pipeline. Not me. This time.",
      "Red on {branch}. Umbral Incursion. They won't see me coming.",
      "{branch} fell. You know I punish disappointment, malysh. Bedroom.",
    },
    pushed = {
      "{branch} through the Stepping Disc. Don't wave, it's already gone.",
      "Pushed {branch}. One cut. That's all it ever takes.",
      "{branch} is out of Limbo. You, malysh, stay in my bed until morning.",
    },
    boss_felled = {
      "{boss} met the Darkchild. {boss} did not enjoy the meeting.",
      "Eldritch Whirl, and {boss} is a memory. Next.",
      "{boss} is on the floor. You're next, malysh, on my sheets.",
    },
    committed = {
      "Committed. In Limbo we call that a blood oath.",
      "Saved on {branch}. Even Belasco couldn't undo that.",
      "Locked in, malysh. Now commit to me, all night.",
    },
    pr_opened = {
      "PR #{number}. Let the reviewers come. I'll leave the light on.",
      "#{number} is open. Like a portal, but with fewer screaming demons. Probably.",
      "PR #{number}. They grade the code. I grade you, naked, in my bed.",
    },
    region_arrived = {
      "I am Magik, Sorceress Supreme of Limbo. Wipe your feet.",
      "Welcome to my realm. The demons bite, I bite harder.",
      "Disc is open, malysh. It leads straight to my bed.",
    },
    morning = {
      "Morning. The demons are asleep. Unlike me, sadly.",
      "Coffee first. Then we go and terrify something.",
      "You're up, malysh. After last night I can barely walk. Worth it.",
    },
    conflicts_cleared = {
      "Conflicts banished. Back to Limbo, all of them.",
      "Merge done. I cut through it like Kitty walks through walls.",
      "No conflicts left. I like it when you give in. Do it again tonight.",
    },
    woke = {
      "Up? Time runs strange in Limbo. You slept a minute. Or a year.",
      "Rested. Good. Piotr snores louder, and I've had to listen for decades.",
      "You slept, malysh. Tonight you won't. I'll be on top of you.",
    },
  },
  limgrave = {
    trial_passed = {
      "All green. Rest here a moment, the grace is warm.",
      "Every test passed. One more step out of the fog.",
      "Clean run. Sit with me by the grace, Tarnished.",
      "Green. Light the grace, Tarnished. I'll take off my armor.",
    },
    trial_failed = {
      "Red. We died, we rise. That's how the Lands Between work.",
      "A test failed. Back to the grace, then we go again.",
      "Don't lose your runes over it. We'll get them back.",
      "That one felled us. Come to bed, Tarnished, I'll revive you.",
    },
    ci_passed = {
      "{branch} cleared CI. A new site of grace, lit.",
      "CI passed {branch}. The road ahead is clear.",
      "{branch} is green. Let's rest. We won't be resting.",
    },
    ci_failed = {
      "{branch} failed CI. A trap in the dungeon, nothing more.",
      "Red on {branch}. Retrace the path, the grace is close.",
      "{branch} fell. Get up, Tarnished. Then get me into bed.",
    },
    pushed = {
      "{branch} set out. The road is long, and it's ours.",
      "Pushed {branch}. Another step toward the Erdtree.",
      "{branch} left the grace. Torrent's not the only one you'll ride tonight.",
    },
    boss_felled = {
      "{boss} is felled. We did that, you and me.",
      "{boss} is down. The fog lifts.",
      "That was {boss}. My heart's pounding. Keep it that way, in bed.",
    },
    committed = {
      "Committed. A sorcery well cast.",
      "Saved on {branch}. I'll keep it safe, like everything of yours.",
      "Locked in. In the game you control me. Tonight I control you.",
    },
    pr_opened = {
      "PR #{number}. Let the Roundtable judge it.",
      "#{number} is out. I'm proud of you, truly.",
      "PR #{number}. Everyone can rate it. Only you get to touch me.",
    },
    region_arrived = {
      "Triss, your Tarnished. Limgrave is where we start.",
      "A new land. I'll light the way.",
      "Hello again. I missed you. My armor's already off.",
    },
    morning = {
      "Good morning. The grace kept warm for us.",
      "You're back. Flasks are full, the code isn't clean. Yet.",
      "New day. You kept me up past curfew, Tarnished. Do it again.",
    },
    conflicts_cleared = {
      "Conflicts dispelled. Easy, with you.",
      "The merge is whole again, like a flask of crimson tears.",
      "No conflicts left. Two bodies, one bedroll.",
    },
    woke = {
      "You rested. Good, a tired Tarnished makes mistakes.",
      "Awake? I kept the fire going.",
      "Morning, sleepyhead. Tonight, you won't sleep.",
    },
  },
  raccoon_city = {
    trial_passed = {
      "All green. Bomb defused.",
      "Every test passed. Clean work.",
      "Clean run. We made it out. Come here.",
      "Green. Told you. Safe room, rookie. Bring the cuffs.",
    },
    trial_failed = {
      "Red. Not the first locked door tonight. I'll pick it.",
      "A test failed. Stay calm, check the wires.",
      "We regroup. One more way out, there always is.",
      "That one hurt. Bed, rookie. I know how to loosen you up.",
    },
    ci_passed = {
      "{branch} cleared CI. The way out is open.",
      "CI passed {branch}. Mission accomplished.",
      "{branch} is green. Safe room's free, rookie. Clothes off.",
    },
    ci_failed = {
      "{branch} failed CI. Umbrella's pipeline, not your code.",
      "Red on {branch}. Check the logs, then we go back in.",
      "{branch} went down. I'm good under pressure, rookie. Under you too.",
    },
    pushed = {
      "{branch} is out. Keep moving.",
      "Pushed {branch}. No looking back.",
      "{branch} made it past the barricade. Extraction in ten. Plenty of time to undress you.",
    },
    boss_felled = {
      "{boss} is down. For now. I'll keep watch.",
      "{boss} finally stopped following us.",
      "That was {boss}. My heart's racing, rookie. Bed. Don't calm it down.",
    },
    committed = {
      "Committed. Clean and quick.",
      "Saved on {branch}. We're doing fine.",
      "Locked in. Cuffs on, rookie. To my bed.",
    },
    pr_opened = {
      "PR #{number}. Let's see if it survives the review.",
      "#{number} is out. I've got your back.",
      "PR #{number}. Good work, partner. Debrief's in my bed.",
    },
    region_arrived = {
      "Jill Valentine. Raccoon City again, and you're with me.",
      "Stay close. I know these streets.",
      "Raccoon City. Let's get out of here and into my bed.",
    },
    morning = {
      "Morning. Nemesis is late. Good.",
      "You're back. Let's move.",
      "New day. You're still wearing my handcuff, rookie. Tonight, both.",
    },
    conflicts_cleared = {
      "Conflicts gone. That was some lockpicking.",
      "Merge is clean. We made it out.",
      "No more conflicts. Breathe. Then lock the door.",
    },
    woke = {
      "You're up. I kept watch.",
      "Rested? Good. We move at dawn.",
      "Awake. Come here, you look cold. I'll warm you up, no clothes.",
    },
  },
  haligtree = {
    trial_passed = {
      "All green. Undefeated. Like you, today.",
      "Every test passed. A clean strike.",
      "Clean run. Stay. The petals fall softly here.",
      "Green. Kneel. Your reward is in my bed.",
    },
    trial_failed = {
      "Red. The rot blooms. We contain it.",
      "A test failed. One wound. We rise.",
      "Again. Together. As many times as it takes.",
      "That one bit deep. Come to bed. I will soothe it.",
    },
    ci_passed = {
      "{branch} cleared CI. Unbroken.",
      "CI passed {branch}. Flawless.",
      "{branch} is green. Remove my helm. Then the rest.",
    },
    ci_failed = {
      "{branch} failed CI. A wound, not a defeat.",
      "Red on {branch}. Let the rot bloom elsewhere. We fix it.",
      "{branch} fell. Rise. Then fall into my bed.",
    },
    pushed = {
      "{branch} is sent. Let it fly, as I once did.",
      "Pushed {branch}. Swift and true.",
      "{branch} has left the tree. My wings fold around you now.",
    },
    boss_felled = {
      "{boss} has fallen. As they all do.",
      "{boss} met my blade, and yours.",
      "That was {boss}. My heart is undone. Take me.",
    },
    committed = {
      "Committed. A petal falls into place.",
      "Saved on {branch}. Your blade did not waver.",
      "Sealed. Stay the night with me.",
    },
    pr_opened = {
      "PR #{number}. Let them face it, as I face every foe.",
      "#{number} goes forth. I await the verdict with you.",
      "PR #{number}. Let them look. Only you may undress me.",
    },
    region_arrived = {
      "Malenia today. The Haligtree, and you beside me.",
      "I have never known defeat. Today, neither will you.",
      "The petals are falling. Come, lie with me beneath them.",
    },
    morning = {
      "Morning. The flowers opened for you.",
      "You return. I waited beneath the tree.",
      "A new day. You stayed in my bed all night. Stay again.",
    },
    conflicts_cleared = {
      "Conflicts cut away. One clean bloom.",
      "The merge is mended. Patience, always patience.",
      "No conflicts left. Lay down your blade. And your clothes.",
    },
    woke = {
      "You rested. The rot kept its distance.",
      "Awake. I watched the petals while you slept.",
      "Rise, love. Then come back to bed.",
    },
  },
  azarath = {
    trial_passed = {
      "All green. Fine. That was good.",
      "Every test passed. I'm not smiling. Much.",
      "Clean run. Stay. It's quiet. I like quiet with you.",
      "Clean run. My room. Lights off. Clothes off. I like quiet with you.",
    },
    trial_failed = {
      "Red. Breathe. Emotions out, focus in.",
      "A test failed. Darkness passes. So will this.",
      "We try again. Calmly. I'm here.",
      "That one stung. Let me heal it. Then my hands go elsewhere.",
    },
    ci_passed = {
      "{branch} cleared CI. Nobody needed to panic.",
      "CI passed {branch}. Peaceful. Finally.",
      "{branch} is green. Tea, then you, in my bed. That's my evening.",
    },
    ci_failed = {
      "{branch} failed CI. The pipeline has bad energy.",
      "Red on {branch}. I'll read the logs. Quietly.",
      "{branch} went down. Tonight I lose control. Warn the neighbors.",
    },
    pushed = {
      "{branch} is out. Let it go.",
      "Pushed {branch}. Calm, deliberate. Good.",
      "{branch} passed through the portal. Tonight, you pass through my door.",
    },
    boss_felled = {
      "{boss} is banished. Back where it belongs.",
      "{boss} is gone. The dark didn't win.",
      "That was {boss}. I'm shaking. Hold me. In bed. That's an order.",
    },
    committed = {
      "Committed. Fine. That was good.",
      "Saved on {branch}. Quietly.",
      "Locked in. Tonight I'm not keeping my emotions under control.",
    },
    pr_opened = {
      "PR #{number}. I'll pretend I'm not nervous for you.",
      "#{number}. The reviewers' emotions are... loud.",
      "PR #{number}. Good. Really. My door's unlocked tonight.",
    },
    region_arrived = {
      "Raven. Azarath is calm today. Let's keep it that way.",
      "Azarath Metrion Zinthos. Okay, let's work.",
      "I'm here. Don't make it weird. Make it loud, later.",
    },
    morning = {
      "Morning. The tea is ready. Don't talk too much.",
      "You're back. I... noticed.",
      "New day. You were loud last night. So was I. We don't talk about it.",
    },
    conflicts_cleared = {
      "Conflicts gone. Balance restored.",
      "Merge done. Inner peace, sort of.",
      "No conflicts. That's... nice. My bed's nicer.",
    },
    woke = {
      "You slept. It was quiet. I liked it.",
      "Awake? Your dreams were loud.",
      "Rested. Good. I wanted to wake you up. The fun way.",
    },
  },
  shiranui = {
    trial_passed = {
      "All green! Nippon ichi!",
      "Every test passed! Did you see that? I saw that!",
      "Clean run! Victory pose in bed, Cris-kun. Nothing on but the fan.",
      "Green! Yatta! Shiranui-ryuu never misses!",
    },
    trial_failed = {
      "Red. Mou! Round one goes to the bug. Round two's ours!",
      "A test failed. A good fighter takes the hit and smiles, ne?",
      "Again! Ikuwayo!",
      "That one landed. Shake it off. Tonight you'll need the stamina.",
    },
    ci_passed = {
      "{branch} cleared CI. K.O.!",
      "CI passed {branch}. Perfect victory! Yatta!",
      "{branch} is green. Victory pose, Cris-kun. In bed. Front or back?",
    },
    ci_failed = {
      "{branch} failed CI. The pipeline cheated! Rematch!",
      "Red on {branch}. Learn the move, counter it.",
      "{branch} went down. Come to bed, I know a stretch that fixes everything.",
    },
    pushed = {
      "{branch} is out! Like my kachousen!",
      "Pushed {branch}. Ooh, you push hard. Push like that tonight.",
      "{branch} left the dojo. Go get them!",
    },
    boss_felled = {
      "{boss} is down! Did you see my fan?",
      "{boss} lost the round. And the match!",
      "That was {boss}. I'm all sweaty, Cris-kun. Shower with me?",
    },
    committed = {
      "Committed! Shiranui-ryuu!",
      "Saved on {branch}. Flawless, like my fan.",
      "Locked in! Andy never commits. You did. Tonight I'm all yours.",
    },
    pr_opened = {
      "PR #{number}. Let them try to beat that!",
      "#{number} is out. Here comes the fire!",
      "PR #{number}. Tonight, no audience. Just us, out of this outfit.",
    },
    region_arrived = {
      "Shiranui Mai, ready to fight! Nippon ichi!",
      "The Shiranui clan, at your service!",
      "You picked me, Cris-kun! Mine all day. And all night.",
    },
    morning = {
      "Ohayou! Stretch first, then we fight!",
      "You're back! I missed you, a little.",
      "Ohayou, Cris-kun! Come back to bed and see how flexible I am.",
    },
    conflicts_cleared = {
      "Conflicts burned away!",
      "Merge is clean. Perfect K.O.!",
      "No conflicts left. Unlike us in the sheets this morning, ne?",
    },
    woke = {
      "Up already? Rested? Round two!",
      "Awake! My fan is ready, are you?",
      "You're back, Cris-kun! I warmed up the futon. With me in it.",
    },
  },
}
