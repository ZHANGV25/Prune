# Prune — Launch checklist

The Debug build uses sandbox credentials. A Release build is **blocked by a build-phase guard** until the RevenueCat sandbox key is swapped for a production key. Most of the App Store plumbing is now automated via Fastlane — see `fastlane/Fastfile` and the lanes below.

## What's automated (already wired up)

- **ASC API key** is installed at `~/.appstoreconnect/private_keys/AuthKey_PVM59TXT82.p8`
- **Issuer ID** `b20319f4-0561-4b65-99f3-ef97d3959ee6` is hardcoded in the Fastfile
- **Bundle ID** `com.isotropic.prune` is registered on the Developer Portal
- `fastlane status` checks Developer Portal + App Store Connect registration
- `fastlane bump` sets build number to a timestamp
- `fastlane beta` builds Release, archives, uploads to TestFlight
- `fastlane release` pushes metadata + screenshots (does NOT auto-submit — keeps a human in the loop)
- `tools/capture_appstore_screenshots.sh` regenerates 6.9" iPhone screenshots

## What still requires your clicks

### 1. ~~Create the App Store Connect app~~ ✓ already done

The "Pruned" app record already exists in App Store Connect (id `6757726140`, bundle `com.isotropic.prune`, SKU `Prune`). Verified via `fastlane status`.

### 2. RevenueCat — create the iOS app in the Prune project

Dashboard → Prune project → **Apps & providers** → **Configurations** → **+ New** → **Apple App Store** → Bundle ID `com.isotropic.prune`. After that:

- **API keys** page will show a new `appl_*` public key — paste it into `Prune/Prune/App/AppConfig.swift` (`revenueCatAPIKey`)
- **Product catalog → Entitlements** → + New → `pro`
- **Products** → create `prune_weekly`, `prune_monthly`, `prune_yearly`, `prune_lifetime`
- **Offerings** → default → attach all 4 products; mark `prune_weekly` as featured
- **Entitlements → pro** → attach all 4 products

Until then, the `test_vUZXRnxl…` sandbox key works for dev and TestFlight. Before shipping, the Release-build guard script will fail the build until the sandbox key is replaced.

### 3. App Store Connect subscription setup

Inside the app record:

- **Agreements, Tax, and Banking** must be **Active** (this blocks submission)
- Create IAP products with IDs matching StoreKit: `prune_weekly`, `prune_monthly`, `prune_yearly`, `prune_lifetime`
- Create one Subscription Group ("Prune Pro") containing the three auto-renewing subs
- Attach a review screenshot to each subscription (required)
- Configure trial: `prune_weekly` has a 3-day free trial

### 4. Legal URLs

Already live at GitHub Pages:

- https://zhangv25.github.io/Prune/privacy
- https://zhangv25.github.io/Prune/terms
- https://zhangv25.github.io/Prune/support

Paste these into App Store Connect's App Information → Privacy Policy URL + Support URL.

## Metadata to copy-paste

Open `APPSTORE_COPY.md`. It contains:

- App name (17 chars, under Apple's 30-char limit)
- Subtitle options
- 100-char keyword string
- Promotional text (170 chars)
- Full description (2,460 chars)
- What's New for v1.0
- Category, age rating, content rights answers
- App Privacy nutrition-label answers (linked: Purchase History, User ID, Crash Data, Performance Data; no tracking)
- Review notes for App Review

## Screenshots

Captured at 1320×2868 (iPhone 17 Pro Max, the 6.9" App Store slot) and saved to `screenshots/appstore/`:

- `01-onboarding-hook.png` — pure SwiftUI, captured via simctl
- `02-onboarding-privacy.png` — pure SwiftUI, captured via simctl
- `03-home-feeds.png` — HomeView with seeded sample data
- `04-celebration.png` — post-delete celebration, mocked 47 photos / ~141 MB freed
- `05-paywall.png` — RevenueCat paywall (prices show RC sandbox defaults until prod products ship)

Re-run with `./tools/capture_appstore_screenshots.sh` any time the UI changes.

### One screenshot needs a real device

The swipe deck shot (`06-swipe-deck.png`) is **not** automated. The iOS 26 simulator shows the photo permission dialog even after `simctl privacy grant` and DB erasure; an XCUITest `addUIInterruptionMonitor` dismisses the dialog but `simctl addmedia`'d photos aren't reliably visible to the test host app on this iOS version.

Workaround: plug in a real iPhone, run the app with a populated photo library, open the swipe deck, and capture the screenshot in Xcode → Window → Devices and Simulators → Take Screenshot. Drop the PNG into `screenshots/appstore/06-swipe-deck.png` before running `fastlane release`.

## Build + ship

Once (1) and (2) above are done:

```
cd "Photo Swiping App"
fastlane status         # verify everything is registered
fastlane beta           # archive, sign, upload to TestFlight
# — test on your iPhone via TestFlight —
fastlane release        # push metadata + screenshots (still doesn't submit)
# — go to ASC, review what got pushed, click Submit for Review when ready —
```

## What's already done in code

- [x] iOS 17 deployment target, iPhone + iPad only, no Mac/Vision
- [x] PrivacyInfo.xcprivacy (no tracking, UserDefaults reason CA92.1, RC purchase/user-ID as linked non-tracking)
- [x] Photo library usage description, ITSAppUsesNonExemptEncryption=NO
- [x] Onboarding (2 pages) ending in photo library permission request
- [x] Freemium gate: 50 swipes/day free on All Photos; Pro unlocks unlimited + smart feeds
- [x] Celebration screen post-delete with approximate bytes freed
- [x] Weekly + monthly + yearly + lifetime tiers in `Prune.storekit`
- [x] Terms + Privacy links + auto-renew disclosure on paywall
- [x] RevenueCat entitlement normalized to `pro`
- [x] Release-build guard blocks ship with sandbox RC key
- [x] 26 unit tests + 4 UI tests (1 E2E skips gracefully when sim has no photos)
- [x] GitHub Actions CI builds + tests on push to main
- [x] Privacy/Terms/Support live on GitHub Pages

## What's NOT tested by automation (needs real-device TestFlight)

- Swipe gesture on a 5K+ photo library (performance, video preload)
- Actual subscription purchase flow in sandbox
- Recently Deleted / restore behavior post-commit
- Limited Access photo permission path
