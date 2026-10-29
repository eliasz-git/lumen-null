# LUMEN NULL roadmap

## Done

- Raycast lidar: forward cone, fading single-color dots with random sizes
  (hunter red, exit cyan), charge-to-trade range for recharge.
- Pause-and-tooltip tutorial (SPACE continues, ESC skips) with a real practice scan.
- Hidden exit gate that only shows when scanned, with a positional chime.
- Hunter: gaunt animated model, patrol / react / investigate / search / chase,
  A* pathing around walls, hears sprinting, line-of-sight chase, lights itself
  up in dots, positional footsteps, heartbeat and alert sting.
- Six data-driven levels (ASCII maps) with escalating difficulty, unlocks and
  per-level best times.
- Title screen with menu music and level select; finish menu (next / replay /
  level select / main menu), death menu, and an ESC pause menu.
- Settings: sensitivity, volume, fullscreen, remappable scan key. macOS launcher
  app runs from source; gamepad supported.
- Exported builds (macOS .dmg, Windows .zip, Linux .tar.gz, Web .zip) published
  as GitHub release v0.4.8 at github.com/tundra-node/lumen-null/releases.
- Headless level checks (`tests/test_levels.gd`): map shape, reachability,
  spawn distance, and a built-level pathing check for every level.
- Playtest tuning: hunter speed, scan recharge and dot lifetime are per-level
  numbers in `scripts/level_data.gd`.
- New objectives: key/door levels (find the key to open the door to the exit).
- Scan-reactive environment: lights that brighten when scanned and doors that
  open when scanned.
- Gamepad support (movement + scan on a gamepad button).
- Walls scale their collision/mesh shape instead of the node.

## Next

- Distraction item (a noisy item to lure the hunter away).
- itch.io publication: the web bundle is ready at builds/web.zip; upload it to
  itch.io (HTML5) — needs itch.io credentials, not yet automated.
- Web Compatibility renderer: the web build uses Forward Plus; consider the
  Compatibility renderer for broader browser support.
- More hunter types.
- Additional levels (add maps to `level_data.gd`; see the README).
