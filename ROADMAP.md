# LUMEN NULL roadmap

## Done

- Raycast lidar: forward cone, fading single-color dots with random sizes
  (hunter red, exit cyan), charge-to-trade range for recharge.
- Pause-and-tooltip tutorial (SPACE continues, ESC skips) with a real practice scan.
- Hidden exit gate that only shows when scanned, with a positional chime.
- Hunter: gaunt animated model, patrol / react / investigate / search / chase,
  A* pathing around walls, hears sprinting, line-of-sight chase, lights itself
  up in dots, positional footsteps, heartbeat and alert sting.
- Four data-driven levels (ASCII maps) with escalating difficulty, unlocks and
  per-level best times.
- Title screen with menu music and level select; finish menu (next / replay /
  level select / main menu), death menu, and an ESC pause menu.
- Settings: sensitivity, volume, fullscreen. macOS launcher app runs from source.
- Headless level checks (`tests/test_levels.gd`): map shape, reachability,
  spawn distance, and a built-level pathing check for every level.

## Next

- Playtest tuning. Hunter speed, scan recharge and dot lifetime are per-level
  numbers in `scripts/level_data.gd`.
- More levels (add a map to `level_data.gd`; see the README).
- New hunter types or objectives (keys, doors, a noisy distraction item).
- Scan-reactive environment (doors, lights).
- Gamepad support, and a remappable scan key (E is read as a raw keycode, not
  an input action).
- Exported builds (macOS, Windows, maybe Web with the Compatibility renderer)
  published as a release or on itch.io. No export presets exist yet.
- Walls are scaled StaticBody3D nodes; Godot recommends scaling the shape
  instead. Works today, worth fixing if physics glitches show up.
