-- What the character of each region says when something happens, written from the voice sheets in
-- docs/voices/elden_ring.md. {branch}, {boss} and {number} are filled in when the moment has them.
return {
  haligtree = {
    trial_passed = {
      "Every test stands. Not one blade bent. Well fought.",
      "Clean. As I expected of you, and only you.",
      "The rot did not touch this. Your hand was steady.",
      "A flawless duel. Miquella would have smiled. So do I.",
    },
    trial_failed = {
      "A wound. Nothing more. Rise, I stand beside you.",
      "The rot blooms here. We cut it out together.",
      "Falter if you must. I will not let you fall.",
      "Again. Patience is the sharpest edge.",
    },
    ci_passed = {
      "{branch} passed every trial. I am proud of you.",
      "{branch} stands untouched. A flower the rot never reached.",
      "No blemish on {branch}. Rest now, beside me.",
    },
    ci_failed = {
      "{branch} has fallen. The duel is not over.",
      "Scarlet rot on {branch}. Hold your blade, I hold mine.",
      "{branch} bled. We have both bled before. Again.",
    },
    pushed = {
      "{branch} goes forth. My blade goes with it.",
      "{branch} is sent. Few keep pace with me. You do.",
      "Go, {branch}. Bloom where they least expect it.",
    },
    boss_felled = {
      "{boss} falls. You fought as I would. Perhaps better.",
      "{boss} is no more. Stay. Let the petals settle.",
      "{boss} kneels before you. I was glad to watch.",
    },
    committed = {
      "Committed. One more petal set in its place.",
      "Your work is sealed on {branch}. Steady hand, steady blade.",
      "A clean cut, committed. I have never known you to waver.",
    },
    pr_opened = {
      "PR #{number} stands before the judges. Let them come.",
      "#{number} is offered up. I will await the verdict with you.",
      "PR #{number}. Bold. Miquella would have approved.",
    },
    region_arrived = {
      "I am Malenia, Blade of Miquella. Today I stand beside you.",
      "The Haligtree welcomes you. Stay close, and the rot stays far.",
      "You have come to me. Good. I have never known defeat, and neither shall you.",
    },
    morning = {
      "Morning. The petals are still, and so is the code. Begin.",
      "You return. I waited, as I always will.",
      "A new day. Draw your blade, I have already drawn mine.",
    },
    conflicts_cleared = {
      "The grafts are cut away. Every branch is whole again.",
      "No conflict left. Two blades, one stance.",
      "The merge is mended. Patience won, as it always does.",
    },
    woke = {
      "You rested. Good. The rot did not move while you slept.",
      "Awake? I kept watch. Nothing touched your code.",
      "Rise. We were never in a hurry, you and I.",
    },
  },
  leyndell = {
    trial_passed = {
      "Every test stands. The Order holds. Let it be so.",
      "Grace is granted. Thy work is consecrated.",
      "All is whole. Hear me, the Order endures.",
    },
    trial_failed = {
      "The tests are broken. Thou shalt mend them.",
      "The Order is shattered. Choose: restore it, or be stripped of grace.",
      "Failure. Thou art not yet worthy. Rise and amend.",
    },
    ci_passed = {
      "{branch} is consecrated. So it is decreed.",
      "Grace upon {branch}. Let it stand.",
      "{branch} endures. The Golden Order is pleased.",
    },
    ci_failed = {
      "{branch} hath fallen from grace. Restore it.",
      "The Order rejects {branch}. Mend it, or let it be shattered.",
      "{branch} is broken. Someone shall answer for this.",
    },
    pushed = {
      "{branch} goes forth. Bear it with grace.",
      "{branch} is sent unto the Lands Between.",
      "Thou hast loosed {branch}. Let it be judged.",
    },
    boss_felled = {
      "{boss} is felled. Take what thou hast earned.",
      "{boss} kneels. The Order is restored.",
      "{boss} is no more. Claim thy grace.",
    },
    committed = {
      "Thy work is sealed upon {branch}. So it is decreed.",
      "Committed. Let the Order record it.",
      "It is written. Thou shalt not unwrite it lightly.",
    },
    pr_opened = {
      "PR #{number} is brought before the Order. Let it be judged.",
      "Hear me: #{number} awaits its verdict.",
      "#{number} is offered. Grace shall decide.",
    },
    region_arrived = {
      "Hear me. I am Marika, and Leyndell is thine this day.",
      "The Erdtree governs all. Today, thou walkest beneath it.",
      "Thou art come to the capital. Bear thyself with grace.",
    },
    morning = {
      "A new day beneath the Erdtree. Rise, and be worthy.",
      "Thou returnest. The Order awaited thee.",
      "Morning. Grace is granted anew. Squander it not.",
    },
    conflicts_cleared = {
      "The rift is mended. One Order, one history.",
      "No conflict remains. As I have willed it.",
      "The shattering is undone. Let none speak of it.",
    },
    woke = {
      "Thou hast rested. Now rise, the Order waits on no one.",
      "Awake. Grace did not leave thee while thou slept.",
      "Rise, Tarnished. Rest is granted, not owed.",
    },
  },
  raya_lucaria = {
    trial_passed = {
      "All pass. Thou art more capable than thou lookest, no?",
      "Well done. Now, onward. The night is long.",
      "Every test holds. I expected no less, truly.",
    },
    trial_failed = {
      "Failing, again? A cold road, this. Walk it anyway.",
      "The tests did not favor thee. How unfortunate.",
      "Red as a lesser moon. Mend it. I shall wait.",
    },
    ci_passed = {
      "{branch} passed. Perhaps thou'rt worth thy service after all.",
      "{branch} is clean. Quiet as the stars.",
      "{branch} hath passed. Mind it doth not go to thy head.",
    },
    ci_failed = {
      "{branch} failed. I did warn thee, no?",
      "{branch} hath fallen. Do not look to me to carry it.",
      "{branch} broke. The dark path is rarely kind.",
    },
    pushed = {
      "{branch} is sent. Farewell, then.",
      "Off goes {branch}, under a cold moon.",
      "{branch} departs. Our plan proceeds.",
    },
    boss_felled = {
      "{boss} falls. Well done. Do not let it go to thy head.",
      "{boss} is no more. Remarkable, no?",
      "{boss} is beaten. One less obstacle before the stars.",
    },
    committed = {
      "Committed. A small step along the path of the stars.",
      "Sealed on {branch}. Thou hast done well, my consort.",
      "It is recorded. The cold night keeps it safe.",
    },
    pr_opened = {
      "PR #{number} is cast. Let us see who dares to read it.",
      "#{number} goes to the academy. They shall not understand it, and that is fine.",
      "PR #{number}. Thy plan unfolds, as mine once did.",
    },
    region_arrived = {
      "I am Ranni. The moon is mine, and tonight, so art thou.",
      "Raya Lucaria. Mind the scholars, they talk far too much.",
      "Thou hast found me. Few do. Stay, and work beneath my moon.",
    },
    morning = {
      "Thou art back. The stars kept their places while thou slept.",
      "A new night, or day. I lose count. Begin, consort.",
      "Morning? How dreadfully bright. Very well, let us work.",
    },
    conflicts_cleared = {
      "The tangle is undone. Order, without the Golden kind.",
      "No conflict left. Cold and clean, as I prefer.",
      "The merge is settled. I knew thou wouldst find the way.",
    },
    woke = {
      "Awake, at last. The moon did not wait, but I did.",
      "Thou hast rested. Good. A dull mind serves no one.",
      "Rise. The age of stars will not write itself.",
    },
  },
  mohgwyn = {
    trial_passed = {
      "Every test passes. Come, the banquet awaits.",
      "A worthy offering. The dynasty grows.",
      "All green. Take thy seat at our table.",
    },
    trial_failed = {
      "The tests bleed. Splendid. More for the rite.",
      "Failure? Nay. An offering of blood.",
      "Red, as all things should be. Nihil.",
    },
    ci_passed = {
      "{branch} is accepted into the dynasty.",
      "{branch} survives the rite. Rejoice.",
      "{branch} is blessed. Raise thy chalice.",
    },
    ci_failed = {
      "{branch} spills its blood. The Formless Mother is pleased.",
      "{branch} failed the rite. We bleed, and begin anew.",
      "Blood on {branch}. Ah, how it flows.",
    },
    pushed = {
      "{branch} goes forth, anointed in blood.",
      "{branch} is sent. Let the feast begin.",
      "Thy offering, {branch}, is received.",
    },
    boss_felled = {
      "{boss} is slain. A fine offering.",
      "{boss} bleeds no more. Its blood is ours.",
      "{boss} falls. The dynasty remembers.",
    },
    committed = {
      "Committed. Thy offering is accepted.",
      "{branch} grows richer. The dynasty swells.",
      "Sealed in blood. Nothing is lost here.",
    },
    pr_opened = {
      "PR #{number} is laid upon the altar.",
      "#{number}. Let them drink of it and be judged.",
      "Behold PR #{number}. A worthy offering.",
    },
    region_arrived = {
      "Welcome, honored guest, to the birthplace of our dynasty.",
      "I am Mohg, Lord of Blood. Thy work shall feed the dynasty.",
      "Mohgwyn opens to thee. Mind the blood, it remembers.",
    },
    morning = {
      "Thou returnest to the palace. The blood still flows.",
      "A new day of the dynasty. Rise, and offer.",
      "Morning. The altar thirsts. Begin.",
    },
    conflicts_cleared = {
      "The conflict is drained. Only one bloodline remains.",
      "No rift left. All is one blood now.",
      "The merge is sealed. Our dynasty grows whole.",
    },
    woke = {
      "Thou wakest. The blood never slept.",
      "Rise, guest. The dynasty awaits thy hand.",
      "Rested? Good. Rested blood flows best.",
    },
  },
  limgrave = {
    trial_passed = {
      "Every test passed. Thy journey goes on.",
      "Well done. Rest a moment by the grace.",
      "All is well. Let us continue.",
    },
    trial_failed = {
      "The tests failed... Rest, then try again. I am here.",
      "Do not lose heart. The grace will guide thee back.",
      "A setback. Return to grace, and begin anew.",
    },
    ci_passed = {
      "{branch} passed. The way ahead is clear.",
      "{branch} is whole. Our accord holds.",
      "{branch} made it through. Shall we go on?",
    },
    ci_failed = {
      "{branch} faltered... We will find the way through.",
      "{branch} did not pass. Rest, then return to it.",
      "{branch} is lost for now. Not forever.",
    },
    pushed = {
      "{branch} goes beyond the fog.",
      "{branch} is sent. Ride on.",
      "Thy work, {branch}, is on its way.",
    },
    boss_felled = {
      "{boss} is felled. Thou art stronger than before.",
      "{boss} is gone. Rest by the grace a while.",
      "{boss} has fallen. The path opens.",
    },
    committed = {
      "Committed. One more step on the road to the Erdtree.",
      "Your work on {branch} is kept. I will remember it with you.",
      "Sealed. Rest here a moment before the next.",
    },
    pr_opened = {
      "PR #{number} is on its way. I will walk beside you while they read it.",
      "#{number} is offered. Whatever they say, the road goes on.",
      "PR #{number}. Your purpose grows clearer, Tarnished.",
    },
    region_arrived = {
      "I am Melina. Let me accompany you through Limgrave.",
      "The grace led you here. So did I.",
      "Limgrave again. Shall we begin, Tarnished?",
    },
    morning = {
      "You're back. The grace stayed warm for you.",
      "A new day. Let me be your maiden, as before.",
      "Morning, Tarnished. Where does the guidance point today?",
    },
    conflicts_cleared = {
      "The paths are joined again. No more crossroads.",
      "No conflict left. The road ahead is one.",
      "The merge is mended. I knew you would find the way through.",
    },
    woke = {
      "You rested well. The fog is thinner now.",
      "Awake? The grace watched over you. So did I.",
      "Rise, Tarnished. The Erdtree is still waiting.",
    },
  },
  farum_azula = {
    trial_passed = {
      "All tests stand. Nothing was stolen this time.",
      "Guarded. As it must be.",
      "The tests hold. Duty done, for the queen.",
    },
    trial_failed = {
      "Failure. Something slipped past my blade. Never again.",
      "The tests fall. Unacceptable. Again.",
      "Broken. Hunt down the cause. Show no mercy.",
    },
    ci_passed = {
      "{branch} is held fast. The seal endures.",
      "{branch} passes. Good.",
      "{branch} stands. Let none take it from thee.",
    },
    ci_failed = {
      "{branch} hath been breached. It shall not happen twice.",
      "{branch} falls. Find the thief. Cut it down.",
      "Failure on {branch}. More. It is not yet enough.",
    },
    pushed = {
      "{branch} goes forth under my guard.",
      "{branch} is sent. Let no thief lay hand upon it.",
      "Go, {branch}. The Black Blade watches.",
    },
    boss_felled = {
      "{boss} is struck down. Death claims its due.",
      "{boss} falls to the Black Blade.",
      "{boss} is ended. The shadow keeps its watch.",
    },
    committed = {
      "Committed. Sealed, as the Black Blade seals Destined Death.",
      "{branch} is bound. Let nothing loosen it.",
      "It is done. Guard it well.",
    },
    pr_opened = {
      "PR #{number} faces judgment. Stand with it.",
      "#{number} goes forth. I shall keep guard while they read.",
      "PR #{number}. Let none steal what thou hast forged.",
    },
    region_arrived = {
      "I am Maliketh, the Black Blade. Farum Azula is under my watch, and so art thou.",
      "The crumbling city greets thee. Mind the edges.",
      "Here the storm never ends. Work as if it never shall.",
    },
    morning = {
      "Thou returnest. The storm did not abate. Neither shall we.",
      "A new day atop the crumbling city. Steel thyself.",
      "Morning. My blade is drawn. Draw thine.",
    },
    conflicts_cleared = {
      "The rot between branches is cut out. Clean.",
      "No conflict remains. I have sealed it away.",
      "The merge holds, as my oath held.",
    },
    woke = {
      "Thou wakest. I kept the vigil.",
      "Rise. Rest is a shield, not a home.",
      "Awake. Good. Death waits, but not for thee today.",
    },
  },
}
