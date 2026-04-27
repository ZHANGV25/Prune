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

## Already pushed to App Store Connect via `fastlane release`

These are LIVE on the v1.0 record at https://appstoreconnect.apple.com/apps/6757726140 — verified via `fastlane probe`:

- ✓ App name (`Prune: Photo Cleaner`), subtitle, primary + secondary categories
- ✓ Description (2,357 chars)
- ✓ Keywords (91 chars: `photo,cleaner,cleanup,swipe,delete,storage,declutter,duplicate,screenshots,selfies,organize`)
- ✓ Promotional text
- ✓ Privacy / support / marketing URLs (all live on GH Pages)
- ✓ 5 of 6 screenshots uploaded to the iPhone 6.9" slot (1320×2868)
- ✓ Copyright notice
- ✓ App Review contact (name, email, phone, notes)

> **Note:** `fastlane/metadata/review_information/phone_number.txt` is gitignored
> (this is a public repo). Add the file locally before running `fastlane release`
> on a new machine.

## What still requires you (in dependency order)

### 2. RevenueCat dashboard (5–10 min, gives you the prod key)

Dashboard → Prune project → **Apps & providers** → **Configurations** → **+ New** → **Apple App Store** → Bundle ID `com.isotropic.prune`. After that:

- **API keys** page will show a new `appl_*` public key — paste it into `Prune/Prune/App/AppConfig.swift` (`revenueCatAPIKey`)
- **Product catalog → Entitlements** → + New → `pro`
- **Products** → create `prune_weekly`, `prune_monthly`, `prune_yearly`, `prune_lifetime`
- **Offerings** → default → attach all 4 products; mark `prune_weekly` as featured
- **Entitlements → pro** → attach all 4 products

Until then, the `test_vUZXRnxl…` sandbox key works for dev and TestFlight. The Release-build guard will fail the build until the sandbox key is replaced.

### 3. App Store Connect — IAPs, Agreements, Privacy (15 min)

Inside the app record:

- **Agreements, Tax, and Banking** → **Active** (Apple-side delay can be 24–48h after submission)
- **In-App Purchases** → create products matching the StoreKit IDs: `prune_weekly`, `prune_monthly`, `prune_yearly`, `prune_lifetime`
- **Subscription Group** → "Prune Pro" containing the three auto-renewing subs (lifetime is non-consumable)
- Attach a review screenshot to each subscription/IAP (use `screenshots/appstore/05-paywall.png` for all four)
- Set trial on `prune_weekly`: 3 days free
- **App Privacy** → fill nutrition label per `APPSTORE_COPY.md` § "Privacy" (Purchase History + User ID + Crash + Performance = linked, not tracking)
- **Age Rating** → 4+, all questionnaire answers None

### 4. The 6th screenshot (real-device capture)

The swipe deck shot (`06-swipe-deck.png`) needs a real iPhone — iOS 26 simulator can't reliably render it via XCUITest. After `fastlane beta` installs to TestFlight, screenshot from device, drop into `screenshots/appstore/06-swipe-deck.png`, and re-run `fastlane upload_screens`.

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

## Build + ship (the rest of the sequence)

```
cd "Photo Swiping App"
fastlane probe          # confirms what's currently in ASC
# After (1)+(2)+(3) above:
fastlane beta           # archives Release, uploads to TestFlight (Apple-signed automatically)
# Test on your iPhone via TestFlight, capture 06-swipe-deck.png from device
fastlane upload_screens # re-pushes the now-complete 6 screenshots
# Then in ASC: review version 1.0 → Add for Review → Submit for Review
```

## Fastlane lanes available

| Lane | What it does |
|---|---|
| `status` | Bundle ID + ASC app registration check |
| `probe` | Dump current metadata/version/build state from ASC |
| `inventory` | List every app + bundle ID this API key can see |
| `bump` | Increment build number to current timestamp |
| `beta` | Archive Release config and upload to TestFlight |
| `upload_screens` | Push only screenshots (skip metadata) |
| `release` | Push metadata + screenshots, no auto-submit |
| `create_app` | (No longer needed — app already exists) |

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
