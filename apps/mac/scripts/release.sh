#!/usr/bin/env bash
# Build, sign, notarize, and package Odyssey.app into a distributable DMG.
#
# Prereqs (one-time):
#   - "Developer ID Application: …" cert installed in the login keychain
#   - App Store Connect API key at ~/.appstoreconnect/private_keys/AuthKey_<id>.p8
#   - apps/mac/.env.release with: ASC_KEY_ID, ASC_ISSUER_ID, DEV_ID_APP, TEAM_ID
#
# Usage: apps/mac/scripts/release.sh [version]
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAC="$(cd "$HERE/.." && pwd)"
cd "$MAC"

APP_NAME="Odyssey"
BUNDLE_ID="io.traf.odyssey"
DIST="$MAC/dist"
APP="$DIST/$APP_NAME.app"
DMG="$DIST/$APP_NAME.dmg"
KEYS_DIR="$HOME/.appstoreconnect/private_keys"

# --- Credentials -------------------------------------------------------------
[ -f "$MAC/.env.release" ] || { echo "✗ Missing apps/mac/.env.release"; exit 1; }
set -a; . "$MAC/.env.release"; set +a
: "${ASC_KEY_ID:?set ASC_KEY_ID in .env.release}"
: "${ASC_ISSUER_ID:?set ASC_ISSUER_ID in .env.release}"
: "${DEV_ID_APP:?set DEV_ID_APP (e.g. 'Developer ID Application: J Traf (TEAMID)')}"
P8="$KEYS_DIR/AuthKey_$ASC_KEY_ID.p8"
[ -f "$P8" ] || { echo "✗ Missing key: $P8"; exit 1; }

VERSION="${1:-$(date +%Y.%m.%d)}"
echo "→ Releasing $APP_NAME $VERSION"

# --- Build release binary ----------------------------------------------------
echo "→ Building release binary…"
swift build -c release >/dev/null
BIN="$(swift build -c release --show-bin-path)/$APP_NAME"
BUNDLE="$(swift build -c release --show-bin-path)/${APP_NAME}_${APP_NAME}.bundle"

# --- Assemble .app bundle ----------------------------------------------------
echo "→ Assembling $APP_NAME.app…"
rm -rf "$DIST" && mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/$APP_NAME"
# SwiftPM resource bundle (icon.png, logo.png, AppIcon.icns)
[ -d "$BUNDLE" ] && cp -R "$BUNDLE" "$APP/Contents/Resources/"
cp "Sources/Odyssey/Resources/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>$APP_NAME</string>
  <key>CFBundleDisplayName</key><string>$APP_NAME</string>
  <key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
  <key>CFBundleExecutable</key><string>$APP_NAME</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>$VERSION</string>
  <key>CFBundleVersion</key><string>$VERSION</string>
  <key>LSMinimumSystemVersion</key><string>26.0</string>
  <key>LSApplicationCategoryType</key><string>public.app-category.photography</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSHumanReadableCopyright</key><string>Unofficial client for Cosmos. Not affiliated with Cosmos.</string>
</dict>
</plist>
PLIST

# --- Sign (hardened runtime) -------------------------------------------------
echo "→ Signing with Developer ID…"
codesign --force --deep --options runtime --timestamp \
  --sign "$DEV_ID_APP" "$APP"
codesign --verify --strict --verbose=2 "$APP"

# --- Package DMG --------------------------------------------------------------
# Same pipeline as vercel-labs/native: HFS+ writable image, Finder AppleScript
# for the window (background, icon size, positions), then UDZO. Finder draws
# the names; the art is dmg.jpg + arrow (Retina TIFF).
echo "→ Building DMG…"
rm -f "$DMG"
"$HERE/dmg.sh" "$APP" "$DMG"
codesign --force --sign "$DEV_ID_APP" "$DMG"

# --- Notarize + staple -------------------------------------------------------
echo "→ Notarizing (this can take a few minutes)…"
xcrun notarytool submit "$DMG" \
  --key "$P8" --key-id "$ASC_KEY_ID" --issuer "$ASC_ISSUER_ID" \
  --wait
xcrun stapler staple "$DMG"
xcrun stapler staple "$APP"

echo "✓ Done: $DMG"
echo "  Verify: spctl -a -t open --context context:primary-signature -v \"$DMG\""
