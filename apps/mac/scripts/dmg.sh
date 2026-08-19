#!/usr/bin/env bash
# Build a drag-to-Applications DMG the way vercel-labs/native does:
# stage the app + Applications link, assemble a Retina TIFF background,
# create a writable HFS+ image, let Finder AppleScript persist the window
# (background, icon size, positions), then convert to compressed UDZO.
#
# Finder draws the names itself — we don't paint them or crop them off.
# HFS+ is required: APFS images drop the .DS_Store Finder writes.
#
# Usage: scripts/dmg.sh <Odyssey.app> <Odyssey.dmg>
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP="${1:?path to Odyssey.app}"
DMG="${2:?output dmg path}"
APP_NAME="$(basename "$APP")"
VOL="${APP_NAME%.app}"

# Native SDK defaults (usable canvas, excluding the title bar).
WIN_W=660 WIN_H=400 TITLEBAR=36
ICON=128
APP_X=166 APP_Y=182
APPS_X=486 APPS_Y=182

WORK="$(mktemp -d "${TMPDIR:-/tmp}/odyssey-dmg.XXXXXX")"
cleanup() {
  hdiutil detach -quiet "$WORK/mount" >/dev/null 2>&1 || true
  rm -rf "$WORK"
}
trap cleanup EXIT

mkdir -p "$WORK/source/.background" "$WORK/mount" "$WORK/assets"

echo "→ Rendering background…"
swift "$HERE/background.swift" "$WORK/assets" >/dev/null
# Native: 1× + @2× PNG → one HiDPI TIFF Finder can display at the canvas size.
tiffutil -cathidpicheck \
  "$WORK/assets/background.png" \
  "$WORK/assets/background@2x.png" \
  -out "$WORK/source/.background/background.tiff" >/dev/null

ditto "$APP" "$WORK/source/$APP_NAME"
ln -s /Applications "$WORK/source/Applications"
# Finder then shows "Odyssey" rather than "Odyssey.app".
SetFile -a E "$WORK/source/$APP_NAME" 2>/dev/null || true

# Don't let an already-mounted copy steal Finder's front window.
hdiutil detach "/Volumes/$VOL" >/dev/null 2>&1 || true

echo "→ Creating image…"
RW="$WORK/staging.dmg"
hdiutil create -quiet -volname "$VOL" -srcfolder "$WORK/source" \
  -ov -format UDRW -fs HFS+ "$RW"
hdiutil attach -quiet "$RW" -mountpoint "$WORK/mount" \
  -nobrowse -noverify -noautoopen

BG="$WORK/mount/.background/background.tiff"
RIGHT=$((100 + WIN_W))
BOTTOM=$((100 + WIN_H + TITLEBAR))
INSET_RIGHT=$((RIGHT - 10))
INSET_BOTTOM=$((BOTTOM - 10))

# Same sequence Native uses: open, style, close, reopen, nudge bounds, close.
# Finder writes a real background bookmark this way; a hand-rolled .DS_Store
# with a stale pBBk is what macOS 26+ discards.
echo "→ Laying out Finder window…"
osascript <<EOF
tell application "Finder"
  set dmgFolder to POSIX file "$WORK/mount" as alias
  open dmgFolder
  set dmgWindow to front window
  delay 1
  set current view of dmgWindow to icon view
  set toolbar visible of dmgWindow to false
  set statusbar visible of dmgWindow to false
  set pathbar visible of dmgWindow to false
  set the bounds of dmgWindow to {100, 100, $RIGHT, $BOTTOM}
  set theViewOptions to the icon view options of dmgWindow
  set arrangement of theViewOptions to not arranged
  set icon size of theViewOptions to $ICON
  set text size of theViewOptions to 13
  set label position of theViewOptions to bottom
  -- Picture doesn't always fill the view (titlebar vs canvas mismatch).
  -- Finder's default fill is white; match the field so a leftover
  -- sliver doesn't flash as a bar.
  set background color of theViewOptions to {0, 0, 0}
  set background picture of theViewOptions to (POSIX file "$BG" as alias)
  set position of item "$APP_NAME" of dmgFolder to {$APP_X, $APP_Y}
  set position of item "Applications" of dmgFolder to {$APPS_X, $APPS_Y}
  close dmgWindow
  open dmgFolder
  set dmgWindow to front window
  delay 1
  set statusbar visible of dmgWindow to false
  set the bounds of dmgWindow to {100, 100, $INSET_RIGHT, $INSET_BOTTOM}
  delay 1
  set the bounds of dmgWindow to {100, 100, $RIGHT, $BOTTOM}
  update dmgFolder without registering applications
  delay 1
  close dmgWindow
  delay 2
end tell
EOF

for _ in $(seq 1 50); do
  [ -s "$WORK/mount/.DS_Store" ] && break
  sleep 0.1
done
if [ ! -s "$WORK/mount/.DS_Store" ]; then
  echo "✗ Finder did not persist the window layout (.DS_Store missing)" >&2
  exit 1
fi

hdiutil detach -quiet "$WORK/mount"
hdiutil convert -quiet "$RW" -ov -format UDZO -imagekey zlib-level=9 -o "$DMG"
echo "✓ $DMG"
