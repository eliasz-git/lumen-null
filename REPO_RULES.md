# Repo Rules — LUMEN NULL

These are the working rules for the LUMEN NULL repository. They supplement `AGENTS.md` (agent-facing guidance) and `VERSIONING.md` (release policy).

## Core design rule

> **Information helps the player survive, but information creates danger.** Do not add map-wide reveals.

The player sees only what a scan hits. The hunter reacts to every scan. Any new feature should respect this tradeoff.

## File rules

- **Commit `.uid` and `.import` files together** with the script or asset they belong to. Do not hand-edit them.
- **Scripts and scenes are tightly coupled.** When renaming a script, update every scene that references it.
- **Do not commit `.godot/`** (editor cache) or exported builds. `builds/` is produced by `build_release.sh` and is not part of the source tree.
- **One fact per memory file.** Agent/project context goes in `~/.claude/projects/-Users-elias/memory/`, not in the repo.

## Scene/script coupling

When renaming a script, update every scene that references it. Scenes store `ExtResource` paths to scripts; a renamed script without a matching scene update is a broken level.

## Level data

Levels live in `scripts/level_data.gd` as ASCII maps (36×36). Rules:

- One of each required marker: `P` (player start), `E` (exit).
- Markers `1`–`3` (hunter spawns), `a`–`l` (waypoints), `K` (key), `D` (door), `L` (light), `&` (scan door), `!` (noise item) must appear at most once and never on the border.
- Exit and all patrol waypoints must be reachable from the start (flood-fill).
- Hunter spawns must be at least 10 m from the player start.
- Corridors should be 2 m wide or more (tested hunter pathfinding width).

Add a level: append to `LEVELS`, bump `COUNT`, run `tests/test_levels.gd`.

## Before committing

Run both checks:

```
godot --headless --path . --quit                          # no SCRIPT ERROR
godot --headless --path . --script res://tests/test_levels.gd   # exit 0
```

Then play level 1 through to the finish menu once.

Commit with the noreply identity: `117379918+tundra-node@users.noreply.github.com`

```
git commit -m "..." -m "Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

## PRs

End pull request descriptions with:

```
🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

## Branches

- Default branch is `main`. Do not commit directly to `main` for feature work; branch first.
- Use `gh` CLI for GitHub operations (PRs, issues, API).

## Game rules (do not break)

- No map-wide reveals (scanner shows cone only; hunter dots are local).
- Hunter kills on contact; `kill_radius = 1.1 m`.
- Sprinting is audible to the hunter (~8–11 m); walking is quiet.
- Line-of-sight chase within `chase_radius`; walls block it.
- The exit is invisible until scanned; it emits a positional chime.

## Versioning

See `VERSIONING.md`. One source of truth: `const VERSION` in `scripts/title_screen.gd`.
