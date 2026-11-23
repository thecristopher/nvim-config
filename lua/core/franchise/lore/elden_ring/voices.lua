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
