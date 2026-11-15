-- What __title__ says around the HUD and while Claude works, in its own words. Every key and its
-- plain line is in lua/core/franchise/lines.lua, copy the ones to change: a key left out says
-- the plain line. {character} is the region's character, {traveler} what the world calls you.
return {
  ["hud.greeting_morning"] = "Good morning, {traveler}",
  ["commit.drafting"] = "{character} is drafting your commit with Claude…",
}
