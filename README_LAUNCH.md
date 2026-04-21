# Prune — Pre-Submission Checklist

The Debug build uses Google's test AdMob IDs and RevenueCat's sandbox key. A Release
build is **blocked by a build-phase guard** until you replace them. Work through this
list before archiving.

## 1. Swap credentials

### AdMob (Google)
1. Create an AdMob app at https://apps.admob.com — get the App ID (`ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX`).
2. Create a Native ad unit — get the ad unit ID (`ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX`).
3. Replace in two places:
   - `Prune/Prune/Info.plist` → `GADApplicationIdentifier`
   - `Prune/Prune/App/AppConfig.swift` → `admobAppID` and `admobNativeAdUnitID` (Release branch of `#if DEBUG`)

### RevenueCat
1. Create a project at https://app.revenuecat.com, add an iOS app with bundle ID `com.isotropicstudios.Prune`.
2. Create an Entitlement named `pro` (must match `AppConfig.proEntitlementID`).
3. Create an Offering with products matching the StoreKit file:
   `prune_weekly`, `prune_monthly`, `prune_yearly`, `prune_lifetime`.
4. Attach all four products to the `pro` entitlement.
5. Copy the **Public App-specific API key** (starts with `appl_`).
6. Replace `AppConfig.revenueCatAPIKey` in `Prune/Prune/App/AppConfig.swift`.

### Legal URLs
Replace in `AppConfig.swift`:
- `termsOfUseURL`
- `privacyPolicyURL`
- `supportURL`

All three must resolve to live pages (no Google Docs). Privacy policy must enumerate AdMob and RevenueCat as third-party SDKs.

## 2. App Store Connect

- Agreements, Tax, Banking — all must be "Active" before submission can proceed.
- Create the app listing with bundle ID `com.isotropicstudios.Prune`.
- Create IAP products in App Store Connect with product IDs matching StoreKit:
  `prune_weekly`, `prune_monthly`, `prune_yearly`, `prune_lifetime`.
- Create a single Subscription Group ("Prune Pro") containing weekly + monthly + yearly.
- Attach a screenshot to each subscription product (required for review).
- Submit your subscription with `prune_weekly` marked as the trial-bearing tier.

## 3. Screenshots

Apple only requires two sizes in 2026 (downscales the rest):
- **6.9" iPhone** — 1290×2796 or 1320×2868
- **13" iPad** — 2064×2752 (required only if you keep iPad support)

1–10 per size, PNG or JPG, no alpha.

## 4. Privacy

- PrivacyInfo.xcprivacy is already bundled and declares UserDefaults reason, tracking domains, and collected data types.
- App Privacy nutrition labels in App Store Connect — declare per third party (AdMob tracks; RevenueCat does not).
- Privacy Policy URL must be reachable and enumerate AdMob + RevenueCat.

## 5. TestFlight

1. Archive: Product → Archive (Release configuration).
2. Upload via Organizer → Distribute App → App Store Connect.
3. Internal testing (100 Apple IDs on team) — no review.
4. External testing — first build of each version string requires Beta App Review (typically 24–48 hours).
5. Fill the "Test Information" block: what to test, demo creds (none needed), contact email. Missing this gets you soft-rejected.

## 6. Common 2025–2026 rejection reasons to watch

- ATT prompt wording that promises a reward ("Allow to unlock…") — rejected under 5.1.1(iv).
- Paywall missing visible Terms + Privacy links or "X to close" button — #1 paywall rejection.
- Fabricated scan counts on first launch ("1,247 junk photos found!") — Apple cracked down in 2025.
- Dead Privacy Policy / Support URL — instant reject.

## 7. What's already done

- [x] iOS 17 deployment target, iPhone + iPad, iOS-only platforms
- [x] PrivacyInfo.xcprivacy with UserDefaults, tracking domains, collected types
- [x] NSUserTrackingUsageDescription, ITSAppUsesNonExemptEncryption=NO, 50 SKAdNetworkItems
- [x] Onboarding (3 pages) with ATT pre-prompt
- [x] Photo permission handled via system dialog after onboarding
- [x] Celebration screen post-delete with approximate bytes freed
- [x] Weekly $6.99 / 3-day-trial tier added to StoreKit (matches category leaders)
- [x] Terms + Privacy links wired on paywall + subscription auto-renew disclosure
- [x] RevenueCat entitlement normalized to `pro`
- [x] Build-phase guard blocks Release builds with test IDs
- [x] 19 unit tests + 3 UI tests, all passing
- [x] Unit tests caught two real bugs: SeenPhotosService deinit crash (from Swift 6 back-deploy + global MainActor isolation) and does(_:match:...) ignoring injected `now` for Today/Yesterday.

## 8. What's not covered by automated tests

Needs a real-device TestFlight pass on a 5K+ photo library:
- Swipe performance with a large library
- Video preloading + playback
- Ad interleaving + undo-over-ads state machine
- Actual purchase flow with sandbox Apple ID
- Permission denial / limited access paths
