-- What the character of each region says when something happens, written from the voice sheets
-- in docs/voices/elden_ring.md. {branch} and {boss} are filled in when the moment has them.
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
  },
}
