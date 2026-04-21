#!/bin/bash
# Captures App Store screenshots at 1290x2796 (6.9" iPhone Pro Max).
# Usage: ./tools/capture_appstore_screenshots.sh
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

seed_photos() {
  # Seed sim with a handful of diverse photos so the swipe deck has content.
  # Uses repo docs (OSS images) as filler.
  PHOTOS=()
  for img in /Users/victor/Documents/Dev/BibleBuddyKids/public/images/stories/*.png; do
    PHOTOS+=("$img")
  done
  if [ ${#PHOTOS[@]} -gt 0 ]; then
    echo "Seeding ${#PHOTOS[@]} photos..."
    # Add in batches to avoid argv limits
    for img in "${PHOTOS[@]:0:30}"; do
      xcrun simctl addmedia "$DEVICE" "$img" 2>/dev/null || true
    done
  fi
}

reinstall() {
  xcrun simctl terminate "$DEVICE" "$BUNDLE" 2>/dev/null || true
  xcrun simctl uninstall "$DEVICE" "$BUNDLE" 2>/dev/null || true
  xcrun simctl privacy "$DEVICE" grant photos "$BUNDLE" 2>/dev/null || true
  xcrun simctl install "$DEVICE" "$APP_PATH"
}

launch_with() {
  local args="$1"
  xcrun simctl launch "$DEVICE" "$BUNDLE" $args
}

shoot() {
  local name="$1"
  sleep 2
  xcrun simctl io "$DEVICE" screenshot "$OUT/$name.png"
  echo "  → $OUT/$name.png"
}

echo "=== Prune App Store screenshot capture ==="
boot_if_needed
seed_photos
reinstall

# 1. Onboarding page 1 (hook)
echo "Capturing onboarding p1..."
xcrun simctl terminate "$DEVICE" "$BUNDLE" 2>/dev/null || true
launch_with "-UITEST_ONBOARD_P1"
shoot "01-onboarding-hook"

# 2. Onboarding page 2 (privacy + permissions)
echo "Capturing onboarding p2..."
xcrun simctl terminate "$DEVICE" "$BUNDLE" 2>/dev/null || true
launch_with "-UITEST_ONBOARD_P2"
shoot "02-onboarding-privacy"

# 3. Home screen with all feeds visible
echo "Capturing home..."
xcrun simctl terminate "$DEVICE" "$BUNDLE" 2>/dev/null || true
launch_with "-UITEST_SKIP_ONBOARDING"
shoot "03-home-feeds"

# 4. Paywall
echo "Capturing paywall..."
xcrun simctl terminate "$DEVICE" "$BUNDLE" 2>/dev/null || true
launch_with "-UITEST_SKIP_ONBOARDING -UITEST_OPEN_PAYWALL"
shoot "04-paywall"

echo
echo "Done. Screenshots saved to $OUT"
ls -lh "$OUT/"
