# LUMEN NULL

You wake up blind in the dark, armed with a lidar scanner instead of a flashlight.
Every scan fires a cone of rays ahead of you and paints the world as fading white
dots. Somewhere in the facility is a hidden exit gate. Something tall and thin
is patrolling it, and it hears every scan you fire.

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

- The world is pitch black. A scan leaves white dots (random sizes) that fade
  after about six seconds. Hunter hits show red, the exit gate shows cyan.
- The exit gate is hidden. Scan to find it, and listen for its chime.
- The hunter patrols, hears every scan, walks (around walls) to where you
  scanned from, searches, then resumes patrolling. It also hears you sprinting
  within a few meters, and it chases if you get close with a clear line of sight.
- Footsteps, a heartbeat, and a hunter alert sting are all positional.
- Hold E longer for more rays and range at the cost of a longer recharge.
- The tutorial pauses the game on each step (SPACE continues, ESC skips). The
  practice scan does not alert the hunter. Your best time is saved.

## Structure

```
project.godot          - Godot 4.7 project, autoloads GameState + GameSettings
scenes/
  level.tscn           - tutorial arena: start bay, cover, pillars, hunter, hidden exit
  exit_beacon.tscn     - the exit gate (invisible; scannable; chimes)
  player.tscn          - first-person controller with the LiDAR camera
  enemy.tscn           - the hunter (procedural model, see hunter_model.gd)
  hud.tscn             - vignette, reticle, charge/cooldown meter, tooltips, overlays
scripts/
  game_state.gd        - autoload: win/lose, run timer, charge/cooldown for HUD
  game_settings.gd     - autoload: sensitivity, volume, fullscreen, best time
  player.gd            - movement, footsteps, charge-and-release scan
  scanner.gd           - cone raycast LiDAR, fading point-cloud MultiMesh
  enemy.gd             - hunter state machine: patrol/react/investigate/search/chase
  hunter_model.gd      - gaunt animated figure whose parts are scannable bodies
  nav_grid.gd          - AStarGrid2D built from level collision for hunter pathing
  level_director.gd    - pause-and-tooltip tutorial
  exit_beacon.gd, ambience.gd, enemy_spawner.gd, win_zone.gd, hud.gd, title_screen.gd
shaders/
  lidar_points.gdshader  - billboarded, fading, round scan dots
  vignette.gdshader      - screen-edge darkening
sounds/                - ping, death, heartbeat, plus generated footsteps/drone/alert
```

## Current polish direction

The playable prototype is now focused on a short, authored vertical slice:

- Teach the pulse in a safe opening beat.
- Escalate through a hunter encounter and a moving-platform section.
- Give the goal a strong visual/audio payoff.
- Tune jump spacing, pulse timing, and hunter speed through repeated playtests.

See POLISH_ROADMAP.md for the current implementation checklist.
```
