#!/bin/bash
# build_release.sh — Build all LUMEN NULL bundles and create a GitHub release.
# Usage: ./build_release.sh <version> [--skip-release]
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
GODOT="/Applications/Godot.app/Contents/MacOS/Godot"
VERSION="${1:?Usage: ./build_release.sh <version> [--skip-release]}"
SKIP_RELEASE="${2:-}"

cd "$PROJECT_DIR"

echo "==> Verifying Godot version..."
GODOT_VER=$("$GODOT" --version 2>&1 | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
if [ "$GODOT_VER" != "4.7.2" ]; then
  echo "WARNING: Godot is $GODOT_VER, expected 4.7.2"
fi

echo "==> Running headless parse check..."
"$GODOT" --headless --path . --quit 2>&1 | grep -i "SCRIPT ERROR" && { echo "PARSE FAILED"; exit 1; } || true

echo "==> Running level tests..."
"$GODOT" --headless --path . --script res://tests/test_levels.gd 2>&1 | grep -i "ALL LEVEL CHECKS PASSED" || { echo "LEVEL TESTS FAILED"; exit 1; }

echo "==> Cleaning old builds..."
rm -rf builds
mkdir -p builds/macOS builds/windows builds/linux builds/web

echo "==> Exporting macOS..."
"$GODOT" --headless --path . --export-release "macOS" "builds/macOS/LUMEN NULL.app" > /dev/null 2>&1

echo "==> Exporting Windows..."
"$GODOT" --headless --path . --export-release "Windows Desktop" "builds/windows/LUMEN NULL.exe" > /dev/null 2>&1

echo "==> Exporting Linux..."
"$GODOT" --headless --path . --export-release "Linux/X11" "builds/linux/LUMEN NULL.x86_64" > /dev/null 2>&1

echo "==> Exporting Web..."
"$GODOT" --headless --path . --export-release "Web" "builds/web/index.html" > /dev/null 2>&1

echo "==> Packaging macOS DMG..."
rm -rf builds/dmg-stage
mkdir -p builds/dmg-stage
cp -R "builds/macOS/LUMEN NULL.app" builds/dmg-stage/
hdiutil create -volname "LUMEN NULL" -srcfolder builds/dmg-stage -ov -format UDZO -o "builds/LUMEN NULL-$VERSION-macos.dmg" > /dev/null 2>&1
rm -rf builds/dmg-stage

echo "==> Packaging Windows ZIP..."
( cd builds/windows && zip -r -X "../LUMEN NULL-$VERSION-windows.zip" "LUMEN NULL.exe" "LUMEN NULL.pck" > /dev/null 2>&1 )

echo "==> Packaging Linux tar.gz..."
# Recreate AppDir if missing (needs rsvg-convert for icon)
if [ ! -d "builds/linux/AppDir" ]; then
  mkdir -p builds/linux/AppDir
  cp "builds/linux/LUMEN NULL.x86_64" builds/linux/AppDir/
  cp "builds/linux/LUMEN NULL.pck" builds/linux/AppDir/
  if command -v rsvg-convert > /dev/null 2>&1; then
    rsvg-convert -w 256 -h 256 -o builds/linux/AppDir/icon.png "$PROJECT_DIR/icon.svg" 2>/dev/null || true
  fi
  printf '#!/bin/sh\ncd "$(dirname "$0")"\nexec "./LUMEN NULL.x86_64" "$@"\n' > builds/linux/AppDir/AppRun
  chmod +x builds/linux/AppDir/AppRun
  printf '[Desktop Entry]\nName=LUMEN NULL\nComment=First-person lidar stealth game\nExec=LUMEN NULL.x86_64\nIcon=icon\nType=Application\nCategories=Game;\n' > builds/linux/AppDir/lumen-null.desktop
  chmod +x builds/linux/AppDir/lumen-null.desktop
fi
( cd builds/linux && tar -czf "../LUMEN NULL-$VERSION-linux.tar.gz" "LUMEN NULL.x86_64" "LUMEN NULL.pck" "AppDir" )

echo "==> Packaging Web ZIP..."
( cd builds/web && zip -r -X "../web.zip" . > /dev/null 2>&1 )

echo "==> Build artifacts:"
ls -la builds/*.{dmg,zip,tar.gz} 2>/dev/null

if [ "$SKIP_RELEASE" = "--skip-release" ]; then
  echo "==> Skipping GitHub release (--skip-release passed)."
  echo "==> To create the release manually:"
  echo "    gh release create v$VERSION \\"
  echo "      \"builds/LUMEN NULL-$VERSION-macos.dmg\" \\"
  echo "      \"builds/LUMEN NULL-$VERSION-windows.zip\" \\"
  echo "      \"builds/LUMEN NULL-$VERSION-linux.tar.gz\" \\"
  echo "      \"builds/web.zip\" \\"
  echo "      --title \"LUMEN NULL $VERSION\""
  exit 0
fi

echo "==> Creating GitHub release v$VERSION..."
gh release delete "v$VERSION" --yes 2>/dev/null || true
git tag -d "v$VERSION" 2>/dev/null || true
git push origin --delete "v$VERSION" 2>/dev/null || true

gh release create "v$VERSION" \
  "builds/LUMEN NULL-$VERSION-macos.dmg" \
  "builds/LUMEN NULL-$VERSION-windows.zip" \
  "builds/LUMEN NULL-$VERSION-linux.tar.gz" \
  "builds/web.zip" \
  --title "LUMEN NULL $VERSION" \
  --notes "LUMEN NULL $VERSION

## Bundles
- **macOS**: LUMEN NULL-$VERSION-macos.dmg (drag .app to Applications)
- **Windows**: LUMEN NULL-$VERSION-windows.zip (LUMEN NULL.exe + LUMEN NULL.pck)
- **Linux**: LUMEN NULL-$VERSION-linux.tar.gz (extract and run ./LUMEN NULL.x86_64)
- **Web**: web.zip (itch.io-ready HTML5; unzip and serve index.html)

## What's changed
- Six data-driven levels: THE SIGNAL (tutorial), TWINS, CROSSING, BLACKOUT, THE KEY (key/door), STATIC (scan-reactive)
- Gamepad support + remappable scan key
- Key/door objective: find the key to open the door to the exit
- Scan-reactive environment: lights brighten and doors open when scanned
- Noise distraction item: pick up and drop to lure the hunter
- Difficulty system: Normal (minimap) / Hardcore (no help)
- Difficulty selector after clearing a level
- Minimap on Normal difficulty
- Strong blast stuns hunters for 1 second
- Wall shape scaling
- Headless parse + level tests in CI

## Notes
- macOS bundle is ad-hoc signed; Gatekeeper may block it unless you right-click → Open or notarize.
- Built from Godot 4.7.2.
- Web bundle is itch.io-ready (HTML5); itch.io upload needs itch.io credentials.
- Source: https://github.com/tundra-node/lumen-null"

echo "==> Done. Release v$VERSION created."
