# LUMEN NULL

You wake up blind in the dark, armed with a lidar scanner instead of a flashlight.
Every scan fires a cone of rays ahead of you and paints the world as a point
cloud - near surfaces read red, distant ones blue. But the thing hunting you
hears every scan, glows red itself, and searches the last place you lit up.

Pitch doc: LUMEN_NULL_pitch.md.

## Run it

Double-click **LUMEN NULL** in /Applications, or from Spotlight. The app runs
the game straight from `~/Developer/lumen-null`, so every launch uses the
latest code - no build step.

Or run from a terminal:

```bash
godot --path ~/Developer/lumen-null
```

## Controls

- **WASD** - move
- **Shift** - sprint
- **Space** - jump
- **Mouse** - look
- **Hold E / release** - charge and fire a cone-shaped lidar scan (longer charge = more rays, longer range, longer cooldown)
- **Esc** - skip tutorial / release mouse
- **R** - restart after death / win

## Mechanics

- The world is pitch black. Only the scan's point cloud reveals it, and the
  dots fade after a few seconds.
- Color encodes distance: red is close, blue/purple is far.
- Every scan tells the hunter where you were. It flashes red and searches that
  location before going idle again.
- The tutorial pauses the game on each step (ESCAPE skips it). The practice
  scan does not trigger the hunter.

## Structure

```
project.godot          - Godot 4.7 project, autoloads GameState + GameSettings
scenes/
  level.tscn           - tutorial stealth arena: start bay, cover routes, hunter, exit
  exit_beacon.tscn     - destination landmark
  player.tscn          - CharacterBody3D first-person controller with LiDAR camera
  enemy.tscn           - the hunter
  hud.tscn             - vignette, reticle, cooldown meter, tooltips, overlays
scripts/
  game_state.gd        - autoload: win/lose, hunter suppression
  player.gd            - movement, jump, scan trigger, cooldown
  scanner.gd           - cone raycast LiDAR, point-cloud MultiMesh renderer
  enemy.gd             - homes to last scan location, kill on contact
  enemy_spawner.gd     - connects scans to hunters
  level_director.gd    - pause-and-tooltip tutorial flow
  hud.gd / win_zone.gd / game_settings.gd
shaders/
  lidar_points.gdshader  - distance-colored billboarded scan dots
  vignette.gdshader      - screen-edge darkening
```

## Current polish direction

The playable prototype is now focused on a short, authored vertical slice:

- Teach the pulse in a safe opening beat.
- Escalate through a hunter encounter and a moving-platform section.
- Give the goal a strong visual/audio payoff.
- Tune jump spacing, pulse timing, and hunter speed through repeated playtests.

See POLISH_ROADMAP.md for the current implementation checklist.
```
