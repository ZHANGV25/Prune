# Prune — Launch checklist

Most of the App Store plumbing is automated via Fastlane lanes. RevenueCat has been dropped in favor of native StoreKit 2; the Release-build sandbox-key guard is gone.

## What's automated (already wired up)

- **ASC API key** at `~/.appstoreconnect/private_keys/AuthKey_PVM59TXT82.p8`
- **Issuer ID** `b20319f4-0561-4b65-99f3-ef97d3959ee6` hardcoded in the Fastfile
- **Bundle ID** `com.isotropic.prune` registered on the Developer Portal

| Lane | What it does |
|---|---|
| `status` | Bundle ID + ASC app registration check |
| `probe` | Dump current metadata, version, IAP, and sub state from ASC |
| `inventory` | List every app + bundle ID this API key can see |
| `bump` | Increment build number to current timestamp |
| `iaps` | Provision subscription group + 4 IAPs (raw ASC REST, idempotent) |
| `beta` | Archive Release config and upload to TestFlight |
| `upload_screens` | Push only screenshots (skip metadata) |
| `release` | Push metadata + screenshots, no auto-submit |

## Already pushed to App Store Connect (verified via `fastlane probe`)

App record `6757726140` at https://appstoreconnect.apple.com/apps/6757726140:

- ✓ App name, subtitle, description (2,357c), keywords (91c), promo text
- ✓ Privacy/support/marketing URLs (live on GH Pages: `zhangv25.github.io/Prune/`)
- ✓ Primary + secondary categories (Utilities + Photo & Video)
- ✓ All 6 iPhone 6.9" screenshots (1320×2868), including the swipe-deck mock
- ✓ Copyright + App Review contact (name, email, phone, notes)
- ✓ Subscription group "Prune Pro" with en-US localization
- ✓ Subscriptions: `prune_weekly` ($6.99/wk + 3-day free trial), `prune_monthly` ($4.99/mo), `prune_yearly` ($39.99/yr + 1-week free trial). All have en-US localization, USA pricing equalized to 175 territories, and review screenshots.
- ✓ Lifetime non-consumable: `prune_lifetime` ($99.99) with en-US localization, USA-base pricing, review screenshot.
- ✓ Age Rating: 4+ (all categories NONE/false)

Subscriptions and the lifetime IAP currently show `state=MISSING_METADATA`. This is normal pre-build — Apple flips the state to `READY_TO_SUBMIT` once a TestFlight build is uploaded and the IAP records are associated with it.

> **Note:** `fastlane/metadata/review_information/phone_number.txt` is gitignored.
> Add the file locally before running `fastlane release` on a new machine.

## What still requires you (in dependency order)

### 1. App Privacy nutrition labels (1 minute, dashboard only)

The public ASC REST API does not expose App Privacy endpoints — only Apple's iris cookie-auth backend does. After dropping RevenueCat, Prune collects no user data (no analytics SDK, no third-party purchase tracker), so this is a one-click decision in the dashboard:

https://appstoreconnect.apple.com/apps/6757726140/distribution/privacy → **Data Not Collected** → Publish

### 2. TestFlight build (20 min)

`fastlane beta` archives the Release config and uploads to TestFlight. Apple will:
- Process the build (~10 min)
- Auto-flip subscription state from `MISSING_METADATA` → `READY_TO_SUBMIT` once the build is associated
- Allow sandbox testers to actually purchase from `Prune.storekit` products (use a sandbox tester account)

### 3. Submit for review (manual)

In ASC: Version 1.0 → Add for Review → Submit for Review.

## What's done in code

- [x] iOS 17 deployment target, iPhone-only (TARGETED_DEVICE_FAMILY=1), no Mac/Vision/iPad
- [x] **StoreKit 2 native purchases** (`PurchaseService` uses `Product.products(for:)`, `Transaction.updates`, `currentEntitlements`, `AppStore.sync()` for restore). No third-party SDK.
- [x] PrivacyInfo.xcprivacy declares no tracking, UserDefaults reason CA92.1
- [x] Photo library usage description, ITSAppUsesNonExemptEncryption=NO
- [x] Onboarding (2 pages) ending in photo library permission request
- [x] Freemium gate: 50 swipes/day free on All Photos; Pro unlocks unlimited + smart feeds
- [x] Celebration screen post-delete with approximate bytes freed
- [x] Weekly + monthly + yearly + lifetime tiers in `Prune.storekit` matching ASC
- [x] Terms + Privacy links + auto-renew disclosure on paywall
- [x] 26 unit tests + 4 UI tests + screenshot capture
- [x] GitHub Actions CI builds + tests on push to main
- [x] Privacy/Terms/Support live on GitHub Pages

## Screenshots

All 6 captured at 1320×2868 (iPhone 17 Pro Max, the 6.9" App Store slot) and saved to `screenshots/appstore/` and `fastlane/screenshots/en-US/`:

- `01-onboarding-hook.png`, `02-onboarding-privacy.png` — pure SwiftUI, captured via simctl
- `03-home-feeds.png` — HomeView with seeded sample data
- `04-celebration.png` — post-delete celebration, mocked 47 photos / ~141 MB freed
- `05-paywall.png` — paywall (StoreKit displays storekit-file prices in the simulator)
- `06-swipe-deck.png` — `MockDeckView`: procedural sunset-mountain "photo" with deck chrome (back button, counter, KEEP/DELETE labels). Bypasses PHPhotoLibrary so the simulator never shows a permission dialog. Triggered by `-UITEST_SCREENSHOT_DECK`.

Re-capture #6 with:
```
xcodebuild test -scheme Prune \
  -only-testing:PruneUITests/ScreenshotTests/test_capture_swipeDeck \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  -resultBundlePath build/screenshots.xcresult
xcrun xcresulttool export attachments --legacy --path build/screenshots.xcresult \
  --output-path build/screenshots-attachments
# copy the PNG into screenshots/appstore/06-swipe-deck.png and fastlane/screenshots/en-US/
```

Re-capture #1–5 with `./tools/capture_appstore_screenshots.sh`.

## Build + ship (the rest of the sequence)

```
cd "Photo Swiping App"
fastlane probe          # confirms current ASC state
fastlane iaps           # idempotent — re-run anytime to reconcile IAPs/subs/age rating
fastlane beta           # archives Release, uploads to TestFlight
# Set App Privacy in dashboard (#1 above), then in ASC:
# Version 1.0 → Add for Review → Submit for Review
```

## Legacy IAPs in ASC

The `probe` lane shows two orphaned items from earlier experiments:
- `com.isotropic.prune.monthly` (NON_CONSUMABLE, READY_TO_SUBMIT)
- `com.isotropic.prune.subs.monthly` (sub, MISSING_METADATA)

These don't match the StoreKit product IDs the app uses (`prune_*`) so they won't load in-app, but they're cosmetic clutter. Delete in the dashboard if you want a clean record.

## What's NOT tested by automation (needs real-device TestFlight)

- Swipe gesture on a 5K+ photo library (performance, video preload)
- Actual subscription purchase flow in sandbox
- Recently Deleted / restore behavior post-commit
- Limited Access photo permission path
