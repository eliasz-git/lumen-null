# LUMEN NULL

You wake up blind in the dark, armed with a lidar pulse instead of a flashlight.
Every pulse reveals the world for a second - platforms, ledges, exits - then
swallows it back into black. But the thing hunting you hears every pulse and
comes running toward the last place you lit up. Climb to the escape platform.

Pitch doc: `LUMEN_NULL_pitch.md` (in your home directory).

## Run it

```bash
godot --path ~/Developer/lumen-null
```

Or open the folder in the Godot 4.7 editor and press F5.

## Controls

- **WASD** - move
- **Shift** - sprint
- **Space** - jump
- **Mouse** - look
- **E** - lidar pulse (reveals geometry as a fading point-cloud, draws the hunter to that spot)
- **Esc** - release mouse
- **R** - restart after death / win

## Mechanics

- Everything is pitch black. Only a pulse lights up nearby geometry as a
  glowing green point-cloud that fades over ~2 seconds.
- Platforms you see = platforms you remember. The staircase to the goal only
  exists visually while revealed.
- Every pulse also tells the hunter your last position - it walks there while
  invisible. Pinging too often brings it right to you.
- The hunter is stuck on the ground. You're on the stairs. Getting caught is
  death.

## Structure

```
project.godot          - Godot 4.7 project, autoloads GameState
scenes/
  level.tscn           - main scene: ground, staircase, 2 hunters, goal, HUD
  platform.tscn        - reusable lidar-revealed platform
  player.tscn          - CharacterBody3D first-person controller
  enemy.tscn           - the hunter
  hud.tscn             - cooldown meter + death/win overlays
scripts/
  game_state.gd        - autoload: pulse state, enemy targeting, win/lose
  player.gd            - movement, jump, pulse
  enemy.gd             - homes to last pulse location, kill on contact
  enemy_spawner.gd     - connects pulses to hunters
  reveal_mesh.gd       - streams ping state into shader uniforms each frame
  hud.gd / win_zone.gd
shaders/
  reveal.gdshader      - green point-cloud reveal
  enemy_reveal.gdshader- red reveal for the hunter
materials/             - ShaderMaterial instances for the above
```