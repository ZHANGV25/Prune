#!/bin/bash
# Captures App Store screenshots at 1290x2796 (6.9" iPhone Pro Max).
# Strategy: capture pure-SwiftUI states (no photo dialog) first, then attempt
# deck capture which needs a real photo library. The photo permission dialog
# on iOS 26 simulators is sticky and cannot always be suppressed via simctl
# privacy grant — the swipe deck screenshot often needs real-device capture.
set -e

DEVICE="C4A11927-3D9A-421F-AD66-DFB97796EA6F"  # iPhone 17 Pro Max, iOS 26.1
BUNDLE="com.isotropicstudios.Prune"
APP_PATH="/Users/victor/Library/Developer/Xcode/DerivedData/Prune-gfseusqpfpgnvwgqfcdramosyrme/Build/Products/Debug-iphonesimulator/Prune.app"
OUT="$(pwd)/screenshots/appstore"
mkdir -p "$OUT"

boot_if_needed() {
  state=$(xcrun simctl list devices | awk -v id="$DEVICE" '$0 ~ id {print $NF}' | tr -d '()')
  if [ "$state" != "Booted" ]; then
    echo "Booting $DEVICE..."
    xcrun simctl boot "$DEVICE"
    sleep 5
  fi
}

install_fresh() {
  xcrun simctl terminate "$DEVICE" "$BUNDLE" 2>/dev/null || true
  xcrun simctl uninstall "$DEVICE" "$BUNDLE" 2>/dev/null || true
  xcrun simctl install "$DEVICE" "$APP_PATH"
}

launch_with() {
  local args="$1"
  xcrun simctl launch "$DEVICE" "$BUNDLE" $args
}

shoot() {
  local name="$1"
  local delay="${2:-2}"
  sleep "$delay"
  xcrun simctl io "$DEVICE" screenshot "$OUT/$name.png"
  echo "  → $OUT/$name.png"
}

echo "=== Prune App Store screenshot capture ==="
boot_if_needed

# Erase the simulator's photo library so Pass 1 can't trigger the iOS 26
# periodic disclosure dialog. Pass 2 reseeds when needed.
echo "Erasing simulator photo library..."
PHOTO_DB_DIR="$HOME/Library/Developer/CoreSimulator/Devices/$DEVICE/data/Media"
if [ -d "$PHOTO_DB_DIR" ]; then
  rm -rf "$PHOTO_DB_DIR/PhotoData/Photos.sqlite"* 2>/dev/null || true
  rm -rf "$PHOTO_DB_DIR/DCIM" 2>/dev/null || true
  rm -rf "$PHOTO_DB_DIR/PhotoData/CPL" 2>/dev/null || true
  xcrun simctl shutdown "$DEVICE" 2>/dev/null || true
  sleep 1
  xcrun simctl boot "$DEVICE"
  sleep 4
fi

# Reset all privacy so there is no cached prior grant/deny state.
xcrun simctl privacy "$DEVICE" reset all "$BUNDLE" 2>/dev/null || true

# Pass 1: Pure-SwiftUI states that don't touch the photo library.
# Install fresh; do NOT seed photos before these so no "new media" reprompt.
echo
echo "--- Pass 1: SwiftUI-only captures ---"
install_fresh

echo "1. onboarding-hook"
xcrun simctl terminate "$DEVICE" "$BUNDLE" 2>/dev/null || true
launch_with "-UITEST_ONBOARD_P1"
shoot "01-onboarding-hook"

echo "2. onboarding-privacy"
xcrun simctl terminate "$DEVICE" "$BUNDLE" 2>/dev/null || true
launch_with "-UITEST_ONBOARD_P2"
shoot "02-onboarding-privacy"

echo "3. home-feeds"
xcrun simctl terminate "$DEVICE" "$BUNDLE" 2>/dev/null || true
launch_with "-UITEST_SKIP_ONBOARDING"
shoot "03-home-feeds"

echo "4. celebration"
xcrun simctl terminate "$DEVICE" "$BUNDLE" 2>/dev/null || true
launch_with "-UITEST_SHOW_CELEBRATION"
shoot "04-celebration"

echo "5. paywall (needs RC offering network fetch — longer delay)"
xcrun simctl terminate "$DEVICE" "$BUNDLE" 2>/dev/null || true
launch_with "-UITEST_SKIP_ONBOARDING -UITEST_OPEN_PAYWALL"
shoot "05-paywall" 8

# Pass 2: Swipe deck — needs photos + perm dialog dismissed.
# Uses an XCUITest with addUIInterruptionMonitor since simctl privacy grant
# cannot reliably suppress the iOS 26 permission dialog.
echo
echo "--- Pass 2: swipe deck via XCUITest ---"

echo "Seeding photos into library..."
for img in /Users/victor/Documents/Dev/BibleBuddyKids/public/images/stories/*.png; do
  xcrun simctl addmedia "$DEVICE" "$img" 2>/dev/null || true
done
sleep 3

echo "Running ScreenshotTests..."
pushd Prune > /dev/null
rm -rf build/screenshots.xcresult
xcodebuild test \
  -project Prune.xcodeproj \
  -scheme Prune \
  -destination "platform=iOS Simulator,id=$DEVICE" \
  -only-testing:PruneUITests/ScreenshotTests \
  -resultBundlePath build/screenshots.xcresult 2>&1 | tail -3

echo "Extracting screenshots from xcresult..."
rm -rf build/screenshot_attachments
xcrun xcresulttool export attachments \
  --path build/screenshots.xcresult \
  --output-path build/screenshot_attachments >/dev/null 2>&1

# The manifest.json lists exported files with suggested names
if [ -f build/screenshot_attachments/manifest.json ]; then
  python3 <<PYEOF
import json, shutil, os
manifest = json.load(open('build/screenshot_attachments/manifest.json'))
for entry in manifest:
    for att in entry.get('attachments', []):
        suggested = att.get('suggestedHumanReadableName', '')
        exported = att.get('exportedFileName', '')
        # Suggested name format: "06-swipe-deck_0_UUID.png" → pull the leading "06-swipe-deck"
        base = suggested.split('_')[0] if '_' in suggested else suggested.replace('.png','')
        target = os.path.join('..', 'screenshots', 'appstore', base + '.png')
        src = os.path.join('build', 'screenshot_attachments', exported)
        if os.path.exists(src):
            shutil.copy(src, target)
            print(f"  → {target}")
PYEOF
fi
popd > /dev/null

echo
echo "Done."
ls -lh "$OUT/"
