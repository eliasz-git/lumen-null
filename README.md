# LUMEN NULL

*See everything. Be seen.*

You wake up blind in a pitch-black facility, armed with a lidar scanner instead
of a flashlight. Every scan fires a cone of rays ahead of you and paints the
world as fading white dots. Somewhere in the dark is a hidden exit gate, and
something tall and thin is patrolling it. The hunter hears every scan you fire,
walks to where you were, and searches. Seeing is what gives you away.

Think *Scanner Sombre* meets *Alien: Isolation*, played entirely in afterimages.
Built in Godot 4.7 in GDScript. The hunter model is built in code, and the
footsteps, drone, alert sting and menu music are synthesized by script.

## Run it

Double-click **LUMEN NULL** in /Applications, or open it from Spotlight. The app
runs the game straight from `~/Developer/lumen-null`, so every launch uses the
latest code with no build step.

Or from a terminal:

```bash
godot --path ~/Developer/lumen-null
```

## Controls

| Key | Action |
|-----|--------|
| WASD | move |
| Shift | sprint (loud) |
| Space | jump |
| Mouse | look |
| Hold E, release | charge and fire a scan. Longer = more rays and range, longer recharge |
| Esc | skip the tutorial; otherwise pause |
| R | restart the level |
| N / M | next level / main menu (finish and pause menus) |

## Levels

| # | Name | What is harder |
|---|------|----------------|
| 1 | THE SIGNAL | Tutorial. One hunter, which ignores your practice scan. |
| 2 | CROSSING | Zig-zag corridors, one hunter, a slightly longer recharge and shorter dots. |
| 3 | TWINS | A 3x3 grid of rooms, two hunters that notice you from farther away. |
| 4 | BLACKOUT | A braided maze, three hunters, dots that fade in 3.5 s, a 2.4 s recharge. |

Clearing a level unlocks the next and saves your best time. The finish menu
offers next level, replay, level select and main menu.

## How it plays

- **Scanning.** Dots are white, random sizes, and fade over a few seconds
  (faster on harder levels). Hunters show red, the exit gate shows cyan.
- **The exit** is invisible until a scan hits it. It also plays a faint,
  directional chime.
- **The hunter** patrols, and reacts to every scan: it flashes red, paths around
  walls to where you scanned from, searches, then resumes patrolling.
- **It can also find you without a scan**, in two ways:
  - *Sprinting.* It hears sprint footsteps within about 8 to 11 m (varies by
    level) and goes to where you were.
  - *Proximity.* If you are within about 3.5 to 4.5 m with a clear line of
    sight, it spots you and chases. Walls block this.
  
  Walking quietly and keeping walls between you and it avoids both. It kills on
  contact. A hunter that spots you lights itself up in red dots and plays a sting.
- **Sound is positional.** Your footsteps are much quieter than the hunter's, and
  you can hear its footsteps, heartbeat (faster when it is near) and alerts.

## Adding a level

Levels are data. Add an entry to `LEVELS` in `scripts/level_data.gd`, and bump
`COUNT`. A map is 36 rows of 36 characters, one cell = 1 m:

| Char | Meaning |
|------|---------|
| `#` | wall (floor to ceiling) |
| `.` | floor |
| `P` | player start |
| `E` | exit gate |
| `1` to `3` | hunter spawn points |
| `a` to `l` | patrol waypoints |

Each entry also sets `name`, `tagline`, `scan_cooldown`, `dot_lifetime`,
`hunter_speed` (multiplier), `chase_radius`, `noise_radius`, and a `hunters`
list of `{spawn, patrol}` where `patrol` is a string of waypoint letters in
order. Keep the exit reachable and the hunters well away from the start. The
shipped levels use corridors 2 m wide or more, which is what the hunter's
pathfinding has been tested with.

## Structure

```
project.godot          - Godot project; autoloads GameState and GameSettings
scenes/
  level.tscn           - shared level shell; level_builder.gd fills it from level_data.gd
  player.tscn          - first-person controller with the lidar camera
  enemy.tscn           - the hunter (procedural model, see hunter_model.gd)
  exit_beacon.tscn     - the exit gate
  wall.tscn            - a 2x4x2 wall block, scaled by the builder
  hud.tscn             - vignette, reticle, meter, tooltips (hud.gd builds the menus)
  title_screen.tscn    - the title screen (built in title_screen.gd)
scripts/
  game_state.gd        - autoload: current level, win/lose, run timer, scene changes
  game_settings.gd     - autoload: sensitivity, volume, fullscreen, unlocks, best times
  level_data.gd        - the four levels: ASCII maps and difficulty
  level_builder.gd     - builds walls, hunters, start and exit from a map
  level_director.gd    - tutorial (level 1) or level intro banner
  player.gd            - movement, footsteps, charge-and-release scan
  scanner.gd           - cone raycast lidar, fading point-cloud MultiMesh
  enemy.gd             - hunter state machine and senses
  hunter_model.gd      - gaunt animated figure whose parts are scannable bodies
  nav_grid.gd          - A* grid built from level collision, for hunter pathing
  hud.gd, title_screen.gd, ui_theme.gd   - UI
  exit_beacon.gd, ambience.gd, enemy_spawner.gd, win_zone.gd
shaders/               - lidar_points (dots), vignette
materials/             - the two shader materials
sounds/                - ping, death, heartbeat, plus generated footsteps, drone, alert, menu music
ROADMAP.md             - what is done and what is next
```

## Settings and saves

Mouse sensitivity, volume, fullscreen, unlocked levels and best times are saved
to `user://lumen_null_settings.cfg` (on macOS:
`~/Library/Application Support/Godot/app_userdata/LUMEN NULL/`). Delete that
file to reset progress.
