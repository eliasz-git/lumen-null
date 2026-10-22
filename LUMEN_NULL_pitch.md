# LUMEN NULL — Game Pitch Document

## Core Mechanic Options

**Pulse reveal** — player sends out a radar/lidar ping that briefly lights up nearby geometry as wireframe dots/lines, then fades to black. You navigate blind in between pulses.

**Cone/beam sweep** — a rotating scanner beam (like a lighthouse) continuously reveals a thin slice of the world in real time — you see a moving line of terrain.

**Echo-triggered danger** — enemies/hazards are invisible until pinged, but pinging also alerts them to your position (stealth-horror tension).

## Genre Pairings

- **Horror/stealth**: total darkness, limited pulses (battery/cooldown), something hunting you. Each ping = risk/reward — see more, but bring attention.
- **Puzzle/platformer**: rooms only "real" (solid) where scanned — jump on platforms that appear only when pinged, similar to Echo mechanics in music-based games.
- **Racing/vehicle**: driving a rover on an alien surface at night, lidar sweep shows terrain ahead, react fast to what flashes into view.
- **Submarine/deep-sea**: sonar-style pings reveal sea floor, wrecks, creatures — classic sub-sim tension.

## Visual Style

Wireframe/point-cloud aesthetic — black background, glowing green/cyan dots and lines, particles fading over 1-2 seconds. Distinctive, cheap to render, looks great in browser/artifact demo.

## Concept Pitch

You're trapped in a pitch-black facility (or cave, or drowned city) with a handheld/wearable scanner. Each ping shows you geometry — platforms, gaps, ladders — as a fading point-cloud. But something in the dark reacts to sound/light. Bigger pings = more info but more attention. You have to solve "where do I jump" using a tool that also says "here I am" to whatever's hunting you.

## Mechanics Blending Horror/Stealth + Platformer

- **Platforms only exist visually after a ping** — jumping becomes a memory puzzle: ping, memorize layout, move through dark trusting what you saw.
- **Pulse radius/cooldown as resource** — small quick pings are safe but short-range; big pulse reveals whole room but summons enemy or takes long to recharge.
- **Enemy "hearing"** — moves toward your last ping location, not actual location, so ping-and-relocate works as stealth trick.
- **Lidar-invisible hazards** — enemy/trap made of material that doesn't reflect, requiring secondary cues (sound, vibration icons) — "the scan lies to you."
- **Vertical progression** = classic platforming (timed jumps, moving platforms) under uncertainty — don't see platform mid-air unless you spend another pulse.
- **Tension knobs per level**: ping cooldown, ping "loudness", enemy aggression, platform linger time vs instant vanish.

---

## Elevator Pitch

**LUMEN NULL** (working title)

You wake up blind in the dark, armed with a lidar pulse instead of a flashlight. Every ping reveals the world for a second — platforms, ledges, exits — then swallows it back into black. But the thing hunting you hears every pulse and comes running toward the last place you lit up. Survive, solve, and navigate a facility you can only see in flashes, without ever seeing too much.

Think *Limbo* meets *Alien: Isolation*, played entirely in wireframe afterimages.

---

## Two-Sentence Pitch

LUMEN NULL — You navigate a pitch-black facility using lidar pulses that briefly reveal platforms and paths before fading to darkness, but every ping also draws a hunting enemy straight toward your last known position. It's platforming and stealth-horror fused into one tense loop: see enough to survive, but never enough to feel safe.

---

## One-Sentence Hook (50-100 chars)

Blind in the dark, one lidar pulse to find the next platform — but every ping draws the hunter straight to you.

---

## 15-Second Hook

"Blind in the dark, one lidar pulse to find the next platform."
"Something starts walking toward wherever you last lit up."

---

## Problem / Opportunity

- Most stealth-horror games let you see the world and just hide from what's in it
- **Here, seeing is what gives you away**
- No safe way to gather information

---

## Solution

- Player pings (E) to reveal platforms as a point cloud of dots
- Every ping also draws the enemy toward that spot
- Seeing enough to jump means risking being found

---

## Tech Credibility

- Built in **Godot 4** — full engine with 3D physics and character controller built in
- Exports to **browser (HTML5)** now, with option to export to desktop later without rebuilding

---

## Why Now / Why You

- Concept is fully scoped
- Draws on programming logic from coursework, applied to a new language (GDScript) with AI support closing the gap

---

## The Ask

- Feedback on the concept
- Time to build the MVP demo