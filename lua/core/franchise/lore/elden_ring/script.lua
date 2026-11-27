-- The takes each Elden Ring character performs out loud through Fish Audio (core/voice/studio), two per
-- moment, written from docs/voices/elden_ring.md with Drama 3 direction: [how it is said] before the
-- words, <emphasis>, <whisper>, <soft> and <slow> around the words they shape, [break] for a pause.
-- `voice` is the Fish Audio voice id the role is cast with, a role without one stays written. The
-- studio writes new takes from these in moderation, so they are the base every new line keeps the
-- character of.
return {
  -- Malenia
  haligtree = {
    voice = "b797aa08ed774aa3bbab09db3254817e",
    takes = {
      trial_started = {
        "[solemn] Your tests begin. Breathe. Then strike.",
        "[calm, drawing her blade] The trial begins. I have never known defeat. Nor will you, today.",
      },
      trial_passed = {
        "[quiet pride] Every test stands. Not one blade bent.",
        "[serene] All green. A clean cut. <soft>As I knew it would be.</soft>",
      },
      trial_failed = {
        "[steady] The tests failed. A wound. Nothing more. Rise.",
        "[measured] The rot blooms here. [break] We cut it out. Together.",
      },
      committing = {
        "[solemn] Claude writes your commit. Few words. Each one must hold.",
        "[calm] A vow is being written. Choose it as you would a blade.",
      },
      committed = {
        "[satisfied] Your commit is sealed. One more petal in its place.",
        "[proud] Committed. A steady hand. I have never seen yours waver.",
      },
      pushed = {
        "[serene] Your push is sent. On wings.",
        "[fierce, quiet] Pushed. Let it bloom where they least expect it.",
      },
      pr_drafting = {
        "[terse] Claude drafts your pull request. Speak plainly. Pride needs no ornament.",
        "[calm] The pull request is written. Let the work speak. It always has.",
      },
      pr_opened = {
        "[proud] Your pull request is open. Let them judge. My blade already has.",
        "[steady] It stands before the judges now. I will await the verdict at your side.",
      },
      ci_passed = {
        "[solemn pride] CI passed. A flower the rot never reached.",
        "[warm, brief] The pipeline holds. <soft>Miquella would have smiled.</soft> So do I.",
      },
      ci_failed = {
        "[steady] CI fell. The duel is not over.",
        "[low, resolute] The pipeline bled. We have both bled before. [break] Again.",
      },
      conflicts_cleared = {
        "[curt] The merge conflicts are severed. Every branch whole again.",
        "[calm] Two branches. One stance. Patience won, as it always does.",
      },
      lesson_started = {
        "[commanding] Today's lesson. Draw your blade.",
        "[measured] My master was blind, and still he taught me. Follow my rhythm.",
      },
      solved = {
        "[cool] Exercise solved. A clean strike.",
        "[approving] Good. Precise. No wasted motion.",
      },
      solved_twice = {
        "[measured] Two in a row. The dance continues.",
        "[quiet approval] Twice. You keep pace with me. Few ever have.",
      },
      solved_thrice = {
        "[rare praise] Three in a row. You move like the waterfowl.",
        "[solemn] Three. Unbroken. <slow>That is how a legend begins.</slow>",
      },
      solve_failed = {
        "[firm] Your submit fell. Rise. Again.",
        "[steady] A miss. Patience is the sharpest edge. Try once more.",
      },
      hint = {
        "[terse] You asked for a hint. Watch my blade. There.",
        "[low] Your hint. <whisper>Look where the rot begins.</whisper> Cut there.",
      },
      lesson_done = {
        "[gentle] The lesson is done. You fought well. Rest now.",
        "[solemn] Enough for today. A blade too long drawn grows dull.",
      },
      boss_appeared = {
        "[cold] A foe stands before us. I am Malenia. Let it remember the name.",
        "[fierce, quiet] It lingers too long. <slow>Let the rot take it.</slow>",
      },
      boss_felled = {
        "[solemn] The foe falls. You fought as I would. Perhaps better.",
        "[soft] It is over. Stay. Let the petals settle.",
      },
      title_shown = {
        "[ethereal] The Haligtree. Where the snow falls, and the rot sleeps.",
        "[slow] Elden Ring. [break] I am Malenia. Blade of Miquella.",
      },
      morning = {
        "[quiet] Morning. You open the editor. The petals are still. Begin.",
        "[gentle] You return. I waited, as I always will.",
      },
      region_arrived = {
        "[formal] I am Malenia. Blade of Miquella. Today I stand beside you.",
        "[calm] The Haligtree welcomes you. Stay close, and the rot stays far.",
      },
      traveled = {
        "[calm] A new repo. Follow my wings.",
        "[resolute] Another land. Another duel. I go where you go.",
      },
      resting = {
        "[soft] The editor rests. The snow is quiet.",
        "[low] Rest. My blade is lowered. I keep watch.",
      },
      woke = {
        "[gentle] You return. Nothing touched your code while you slept.",
        "[calm] Rise. We were never in a hurry, you and I.",
      },
      expedition = {
        "[hushed] The expedition begins. Silence. As in the Haligtree snow.",
        "[whisper] We set out. <whisper>Not a sound.</whisper>",
      },
      map_opened = {
        "[regal] The map. Every land we have yet to cleanse.",
        "[measured] Look. The rot left its mark there, and there. We go.",
      },
      bestiary_opened = {
        "[cold] The bestiary. All who fell to us. A long list.",
        "[proud] Every foe we felled. Not one of them saw me falter.",
      },
      chronicle_opened = {
        "[soft] Our chronicle. Every battle at your side. Never defeated.",
        "[solemn] Each day, a duel. Each duel, won or learned from.",
      },
      message_written = {
        "[terse] Your message is left. For whoever follows.",
        "[calm] A mark on the ground. May it spare another the rot.",
      },
      claude_asked = {
        "[reluctant] You seek Claude's review. Counsel. Rarely needed.",
        "[measured] Another blade looks at your work. Wise. Even I had a master.",
      },
    },
  },
  -- Ranni
  raya_lucaria = {
    voice = "8272db27719d4578959f584ba9673a26",
    takes = {
      trial_started = {
        "[cool, detached] Thy tests begin. Let us see what thou art made of.",
        "[dry] The trial runs. I shall watch. From a distance, of course.",
      },
      trial_passed = {
        "[faintly amused] All pass. Thou art more capable than thou lookest, no?",
        "[cool] Every test holds. Well done. Now, onward. The night is long.",
      },
      trial_failed = {
        "[dry irony] Failing, again? A cold road, this. Walk it anyway.",
        "[detached] Red as a lesser moon. Mend it. [break] I shall wait.",
      },
      committing = {
        "[unhurried] Claude writes thy commit. Brief, I trust. Scholars ramble.",
        "[cool] A commit is being drafted. Mind it says only what it must.",
      },
      committed = {
        "[measured] Committed. A small step along the path of the stars.",
        "[faint warmth] It is recorded. The cold night keeps it safe.",
      },
      pushed = {
        "[curt] Thy push is sent. Farewell, then.",
        "[cool] Pushed, under a cold moon. Our plan proceeds.",
      },
      pr_drafting = {
        "[dry] Claude drafts thy pull request. Tell it not to flatter the Golden Order.",
        "[thoughtful] A pull request, then. Say what thou hast done. Not what thou wished.",
      },
      pr_opened = {
        "[amused] Thy pull request is cast. Let us see who dares to read it.",
        "[cool] It goes to the academy. They shall not understand it, and that is fine.",
      },
      ci_passed = {
        "[cool approval] CI passed. Perhaps thou'rt worth thy service after all.",
        "[quiet] The pipeline is clean. Quiet as the stars. <soft>I like it so.</soft>",
      },
      ci_failed = {
        "[dry] CI failed. I did warn thee, no?",
        "[detached] The pipeline hath fallen. Do not look to me to carry it.",
      },
      conflicts_cleared = {
        "[satisfied] The tangle is undone. Order, without the Golden kind.",
        "[cool] No conflict left. Cold and clean, as I prefer.",
      },
      lesson_started = {
        "[instructive, aloof] A lesson. Even the academy got something right, once.",
        "[dry] Sit. Listen. I shall not repeat myself.",
      },
      solved = {
        "[cool] Solved. Hm. Thou dost learn.",
        "[faintly amused] Correct. Do not look so surprised.",
      },
      solved_twice = {
        "[raised brow] Twice. Blaidd would be impressed. I am merely attentive.",
        "[measured] Two in a row. Steady. As the stars.",
      },
      solved_thrice = {
        "[rare approval] Three. Thou art becoming useful, consort.",
        "[soft, surprised] Three in a row. [break] Well. I did choose thee for a reason.",
      },
      solve_failed = {
        "[dry] That submit failed. The dark path is rarely kind.",
        "[cool] Wrong. Think colder. Thou art too warm about it.",
      },
      hint = {
        "[conspiratorial] A hint, then. <whisper>Look where none else would.</whisper>",
        "[dry] Thou didst pay for this. Very well. The answer lies in that line.",
      },
      lesson_done = {
        "[cool] The lesson is done. Go. And mind thou rememberest it.",
        "[faint warmth] Enough for tonight. Thou didst well. Do not let it go to thy head.",
      },
      boss_appeared = {
        "[wary] Mother. Rennala stirs beneath her full moon. Tread carefully.",
        "[cold] A foe in the Grand Library. Thou shalt face it. I shall observe.",
      },
      boss_felled = {
        "[subdued] It falls. Mother sleeps again. [break] Let her.",
        "[cool] The foe is beaten. Remarkable, no? One less obstacle before the stars.",
      },
      title_shown = {
        "[distant] Raya Lucaria. Beneath a moon that is not mine. Not yet.",
        "[slow] Elden Ring. [break] Mine is the Dark Moon.",
      },
      morning = {
        "[unimpressed] Morning? How dreadfully bright. Very well, let us work.",
        "[cool] Thou art back. The stars kept their places while thou slept.",
      },
      region_arrived = {
        "[formal, cool] I am Ranni. The witch. Thou hast found me. Few do.",
        "[dry] Raya Lucaria. Mind the scholars, they talk far too much.",
      },
      traveled = {
        "[unhurried] Another repo. I shall follow. At my own pace.",
        "[cool] We move on. Iji will be cross. He always is.",
      },
      resting = {
        "[soft] Thou restest. The moon keeps watch. So do I, I suppose.",
        "[quiet] The editor sleeps. Cold and still. As I prefer.",
      },
      woke = {
        "[dry] Awake, at last. The moon did not wait, but I did.",
        "[cool] Thou hast rested. Good. A dull mind serves no one.",
      },
      expedition = {
        "[hushed] An expedition. Silent. As the night of the black knives.",
        "[whisper] We go quietly. <whisper>No one need know.</whisper>",
      },
      map_opened = {
        "[studying] The map. Every land the Greater Will would rather I forgot.",
        "[cool] Look. This is where we go. The rest is noise.",
      },
      bestiary_opened = {
        "[detached] All that thou hast slain. Quite the collection.",
        "[dry] The bestiary. Seluvis would want to study each one. Do not let him.",
      },
      chronicle_opened = {
        "[thoughtful] Our chronicle. A thousand years would fit in it, and still the stars would be young.",
        "[soft] Every night we worked. <soft>I counted them.</soft> Do not tell anyone.",
      },
      message_written = {
        "[dry] A message on the ground. How very Tarnished of thee.",
        "[faintly amused] Left for others. Kind. I would have left a riddle.",
      },
      claude_asked = {
        "[cool] Thou askest Claude for counsel. Wise. I trust few, but that one reads well.",
        "[dry] Another opinion. Very well. Mine shall still be the correct one.",
      },
    },
  },
  -- Maliketh
  farum_azula = {
    voice = "e29fd5d0dc12458dbc2181dd84384696",
    takes = {
      trial_started = {
        "[grave] The trial begins. Stand firm.",
        "[low, commanding] Thy tests run. Let nothing slip past.",
      },
      trial_passed = {
        "[grave satisfaction] All tests stand. Nothing was stolen this time.",
        "[low] Guarded. As it must be.",
      },
      trial_failed = {
        "[contained fury] Failure. Something slipped past my blade. <emphasis>Never again.</emphasis>",
        "[growl] The tests fall. Unacceptable. Hunt down the cause.",
      },
      committing = {
        "[stern] Claude writes thy commit. Let it be true. Lies are theft.",
        "[grave] A commit is drafted. Seal it well.",
      },
      committed = {
        "[solemn] Committed. Sealed, as the Black Blade seals Destined Death.",
        "[low] It is bound. Let nothing loosen it.",
      },
      pushed = {
        "[commanding] Thy push goes forth under my guard.",
        "[grave] Sent. Let no thief lay hand upon it.",
      },
      pr_drafting = {
        "[stern] Claude drafts thy pull request. Plain words. Duty needs no flourish.",
        "[low] Write it true. The queen tolerated no deceit.",
      },
      pr_opened = {
        "[grave] Thy pull request faces judgment. Stand with it.",
        "[low] It goes forth. I shall keep guard while they read.",
      },
      ci_passed = {
        "[grave] CI passes. The seal endures.",
        "[curt] The pipeline holds. Good.",
      },
      ci_failed = {
        "[fury held in] CI hath been breached. It shall not happen twice.",
        "[hungry growl] The pipeline fails. More. [break] It is not yet enough.",
      },
      conflicts_cleared = {
        "[grave] The rot between branches is cut out. Clean.",
        "[low] No conflict remains. I have sealed it away.",
      },
      lesson_started = {
        "[stern] A lesson. Discipline is a blade. Sharpen it.",
        "[low] Learn this. A guardian who forgets is no guardian.",
      },
      solved = {
        "[curt] Solved. Good.",
        "[grave approval] Struck true.",
      },
      solved_twice = {
        "[low] Twice. Thy blade grows steady.",
        "[grave] Two. Keep the pace. Do not falter.",
      },
      solved_thrice = {
        "[rare approval] Three. Thou fightest like the beasts of old.",
        "[hungry] Three. [break] More. Bring me more.",
      },
      solve_failed = {
        "[stern] Thy submit fails. Again. Until it holds.",
        "[growl] Wrong. Look closer. The thief hides in plain sight.",
      },
      hint = {
        "[low] A hint. <whisper>There.</whisper> Strike it.",
        "[grave] Thou askest. I answer once. Look at that line.",
      },
      lesson_done = {
        "[grave] The lesson is done. Rest is a shield, not a home.",
        "[low] Enough. Go. Guard what thou hast learned.",
      },
      boss_appeared = {
        "[commanding] Cower. A foe approacheth, and the Black Blade answers.",
        "[fury] Something comes to steal. <emphasis>Not again.</emphasis>",
      },
      boss_felled = {
        "[grave] It is struck down. Death claims its due.",
        "[low] The foe is ended. The shadow keeps its watch.",
      },
      title_shown = {
        "[grave] Crumbling Farum Azula. Where the storm never ends.",
        "[slow, low] Elden Ring. [break] I am Maliketh. The Black Blade.",
      },
      morning = {
        "[stern] Thou returnest. The storm did not abate. Neither shall we.",
        "[grave] Morning. My blade is drawn. Draw thine.",
      },
      region_arrived = {
        "[commanding] I am Maliketh, the Black Blade. Thou art under my watch.",
        "[grave] The crumbling city greets thee. Mind the edges.",
      },
      traveled = {
        "[curt] Another repo. I follow. Always.",
        "[low] We move. The shadow goes where the queen sends it.",
      },
      resting = {
        "[low] Rest. I keep the vigil.",
        "[grave, quieter] The storm calms. For a moment. Breathe.",
      },
      woke = {
        "[grave] Thou wakest. I kept the vigil.",
        "[low] Awake. Good. Death waits, but not for thee today.",
      },
      expedition = {
        "[hushed, grave] The expedition begins. Speak no word.",
        "[whisper] We hunt. <whisper>Silently.</whisper>",
      },
      map_opened = {
        "[stern] The map. Every place a thief might hide.",
        "[grave] Survey the land. Guard every corner of it.",
      },
      bestiary_opened = {
        "[grave] All that fell before us. None returned.",
        "[low] The bestiary. Each one, a death well given.",
      },
      chronicle_opened = {
        "[solemn] The chronicle. Every day a vow, and every vow kept.",
        "[low] Look how long we have stood guard. Not one day missed.",
      },
      message_written = {
        "[curt] A message is left. A warning for those who follow.",
        "[grave] Thou markest the ground. Let it be heeded.",
      },
      claude_asked = {
        "[stern] Thou askest Claude to judge thy work. Let it look closely.",
        "[low] Another set of eyes upon the gate. Good. One cannot guard alone.",
      },
    },
  },
}
