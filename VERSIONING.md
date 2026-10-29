# Versioning — LUMEN NULL

## Scheme

We use [Semantic Versioning](https://semver.org/) (semver): `MAJOR.MINOR.PATCH`.

- **MAJOR** — breaking changes to saves, controls, or core systems (rare pre-1.0).
- **MINOR** — new features, new levels, new hunter types, new objectives.
- **PATCH** — bug fixes, tuning, balance, UI tweaks, docs.

Pre-1.0, `MAJOR` stays `0`. `MINOR` is the meaningful release number; `PATCH` is for small fixes between releases.

## Current version

`v0.4.8` — see `scripts/title_screen.gd` (`const VERSION`).

## When to bump

| Change | Bump | Example |
|--------|------|---------|
| New level, mechanic, hunter type, or objective | MINOR | `0.4.7` → `0.5.0` |
| Bug fix, tuning, balance, UI tweak | PATCH | `0.4.7` → `0.4.8` |
| Save-breaking change | MAJOR | `0.x.x` → `1.0.0` |
| Docs / README only | none | no version change |

## Don't over-bump

Don't create a new version for every tiny edit. Group fixes into a single PATCH release, and only cut a release when there's something worth shipping (a new build, a public fix, or a milestone).

## Release process

1. Update `const VERSION` in `scripts/title_screen.gd`.
2. Sync `README.md` and `ROADMAP.md` release references.
3. Run the checks: `godot --headless --path . --quit` and `godot --headless --path . --script res://tests/test_levels.gd`.
4. Play level 1 through to the finish menu (verify no crash).
5. Run `./build_release.sh <version> --skip-release` to build all bundles.
6. Create the GitHub release and tag `v<version>`.
7. Update itch.io web build from `builds/web.zip`.

## Version locations

The version lives in exactly one place in code:

- `scripts/title_screen.gd` — `const VERSION`

Everything else (README, ROADMAP, release titles, build artifacts) is derived from that constant. Do not add a second source of truth.

## Should we even have versions?

**Yes.** This game ships builds (macOS, Windows, Linux, Web) and is headed to itch.io. Players will run different builds, file bug reports, and need to know which version they're on. Remove versions only if you stop distributing builds entirely and go source-only.
