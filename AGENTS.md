# AGENTS.md: LUMEN NULL

First-person stealth game in Godot 4.7, written in GDScript. The player has a lidar scanner instead of a flashlight; a hunter reacts to every scan.

## Stack
Godot 4.7, GDScript only. No external assets: the hunter model is built in code, and sound is synthesized by script.

## Commands
- Run: `godot --path ~/Developer/lumen-null`.
- Headless check for parse errors: `godot --headless --path . --quit` (look for `SCRIPT ERROR`).
- The macOS app in /Applications launches the game straight from this folder, so every launch uses the latest code. There is no build step.

## Layout
- `scenes/`: `.tscn` scenes (`level`, `enemy`, `exit_beacon`, `hud`, `wall`).
- `scripts/`: gameplay (`player`, `enemy`, `scanner`, `level_director`, `nav_grid`, `ambience`, `hunter_model`, `game_state`, `game_settings`, `hud`).
- `shaders/`: `lidar_points.gdshader`. `sounds/`: generated `.wav` plus their `.import` files.
- `POLISH_ROADMAP.md`: what is done and what is next.

## Rules
- Commit each `.uid` and `.import` file together with the script or asset it belongs to. Do not hand-edit them.
- Scripts and scenes are tightly coupled: when renaming a script, update every scene that references it.
- Keep the core tradeoff intact: information helps the player survive, but information creates danger. Do not add map-wide reveals.
- Do not commit `.godot/` (editor cache) or exported builds.

## Before committing
Run the headless check above and play the first level through once. Commit with the noreply identity (`117379918+tundra-node@users.noreply.github.com`).
