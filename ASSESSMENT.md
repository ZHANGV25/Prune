# Prune — is it worth finishing?

Assessment date: 2026-08-23. All App Store Connect facts below were read live from the
ASC API (`fastlane probe` / `inventory`) on that date, not from docs in the repo.

## TL;DR

**Prune is not "scaffolded and never finished." It is finished, built, uploaded to
TestFlight, and one dashboard checkbox away from being submitted for review.** The one
real caveat is that it has never been run against a real photo library — see step 2. It stalled
on 2026-05-22 at 19:08 because an automated step needed an interactive Apple ID password
and the shell was non-interactive. Nothing about the code, the metadata, or the product
caused the stop.

Recommendation: **submit it.** Not because the category looks winnable — it doesn't, on
ASO alone — but because the remaining cost is roughly one evening: a rebuild, a 30-minute
smoke test on your own phone (the delete path has never run against real photos), and a
handful of dashboard clicks. Shipping converts a dead repo into a free, permanent ASO
experiment. Then gate any further engineering on what App Store Connect impressions
actually show.

---

## 1. What's on this disk

26 git repos + 6 loose project folders under `~/Documents/Dev`. Three of them have App
Store Connect records; everything else is unreleased.

| App | ASC state | Last code activity |
|---|---|---|
| **BibleBuddy Kids** (`com.isotropic.biblebuddy`) | v2.0.0 **READY_FOR_SALE** (2026-04-20) | 2026-04-21 |
| **Event Monkey** (`com.isotropic.ev`) | v1.04 **READY_FOR_SALE** (2025-10-15) | 2025-10-19 |
| **Prune: Photo Cleaner** (`com.isotropic.prune`) | v1.0 **PREPARE_FOR_SUBMISSION** | 2026-05-22 |

The rest of the disk, most-recent first: `nexusgto` + `nexusgto-api` + `poker-solver`
(May 2026, the current focus), `finance-app`, `c5dru`, `Tare`, `clover-health-casestudy`,
`insider-leak-signal`, `poker-dashboard`, `AIVS`, `watchtower-{web,api,camera}`,
`ZHANGV25`, `poker-engine-2026`, `ACRPoker-Hud-PC`, `poker`, `FindTheHuman`,
`portfolio-v2`, `EasyClaw`, `QuorumTest`, `AI CRM`, plus non-git folders
`facebook-marketplace-ai`, `SweepstakesPlatform`, `Foreclosure`, `Arbitrage`, `Websites`.

**What you've been experimenting with, technically.** There's a clear trajectory across
the three shipped/shippable apps: Event Monkey was Flutter + Google ML Kit + Firebase +
RevenueCat; BibleBuddy v1 was Capacitor/React + Supabase + Firebase + RevenueCat;
BibleBuddy v2 and Prune are both native SwiftUI + StoreKit 2 with essentially zero
third-party SDKs. You've been steadily shedding dependencies and moving native-first —
and that pays off concretely here: Prune links *no* analytics or purchase SDK, which is
exactly why its pending privacy label is a truthful one-click "Data Not Collected"
instead of a nutrition-label questionnaire.

Worth noting: **BibleBuddyKidsNative shipped.** Its `ROADMAP.md` still has "D11. Submit to
App Store" unchecked, which reads like it stalled — but the SwiftUI rewrite went out as
v2.0.0 under the same bundle ID on 2026-04-20. The roadmap just never got updated. So the
portfolio pattern is *not* "always stops at the door." Two of three apps shipped. **Prune
is the sole exception.**

---

## 2. Prune's actual state (verified)

**Code — complete and healthy.**
- 2,325 lines of Swift across 19 files. SwiftUI + Photos framework, iOS 17+, iPhone-only.
- `xcodebuild -scheme Prune` on Xcode 26.1.1 → **BUILD SUCCEEDED** (re-verified 2026-08-23).
- **Zero third-party dependencies.** No SPM packages in the pbxproj at all. RevenueCat was
  ripped out in favor of native StoreKit 2 (`Product.products(for:)`, `Transaction.updates`,
  `currentEntitlements`, `AppStore.sync()`). AdMob was dropped earlier.
- `AnalyticsService.swift` is a pure `print()` stub — no Firebase linked. This matters: it
  means the pending **"Data Not Collected"** privacy declaration is *truthful*, not a
  shortcut. That step really is one click.
- 26 unit tests + 4 UI tests + automated screenshot capture + GitHub Actions CI.

**App Store Connect — essentially fully provisioned.**
- App record `6757726140`, "Prune: Photo Cleaner".
- Metadata live: 91-char keywords, 2,357-char description, promo text, both categories,
  age rating 4+, review contact, and 6 iPhone 6.9" screenshots at 1320×2868.
- Privacy / terms / support pages live on GitHub Pages.
- Build `2605221844` uploaded 2026-05-22, `processing=VALID`.
- Subscriptions `prune_weekly` / `prune_monthly` / `prune_yearly` and non-consumable
  `prune_lifetime` all exist with localization, pricing across 175 territories, and review
  screenshots.

**Where it actually died.** The timeline on 2026-05-22 is unambiguous:
- **18:45** — `fastlane beta` succeeds. `Prune.ipa` + dSYM written to `build/fastlane/`,
  uploaded to TestFlight.
- **19:08** — `fastlane privacy` fails. From `fastlane/report.xml`:
  > `Missing password for user vhzhang2020@gmail.com, and running in non-interactive shell`

  App Privacy nutrition labels are the one thing Apple does *not* expose on the public ASC
  REST API — they require Apple's cookie-auth iris backend, i.e. an interactive password.
  Every other step in this project was automatable and got automated. This one wasn't, the
  agent session couldn't do it, and the project stopped there. Three months ago.

---

## 3. What's actually left

Real remaining work, in order. Call it one evening — but note step 2, which is the only
item with genuine unknown risk.

1. **Re-run `fastlane beta`** (~20 min, mostly waiting). Build `2605221844` has aged past
   the 90-day TestFlight testing window (`exp=true`), and you want a fresh build on your
   phone for step 2 regardless. *(Expiry itself isn't alarming — every build across all
   three apps shows `exp=true`, including BibleBuddy's April builds under a shipped
   v2.0.0. It's the normal testing window, not a defect.)*

2. **Smoke-test on a real device — do not skip this.** `README_LAUNCH.md` has a
   "What's NOT tested by automation" list, and it names exactly the things that matter for
   an app whose entire job is deleting photos:
   - the swipe deck against a 5K+ photo library (performance, video preload)
   - the actual `PHPhotoLibrary.performChanges` delete commit
   - Recently Deleted / restore behavior after commit
   - the Limited Access permission path

   `BUILD SUCCEEDED` and 26 unit tests touch none of this — the simulator has no real
   photo library, which the README says outright. **Nobody has ever run this app against
   real photos.** Install the TestFlight build, swipe ~50 real photos, confirm they land in
   Recently Deleted, and sanity-check the freed-bytes number on the celebration screen.
   Then re-run granting *Limited* access only, since `PhotoLibraryService` tracks
   `isLimited` but nothing verifies that path renders anything. 30 minutes. A photo cleaner
   that mis-deletes is worse than one that never ships.

3. **Fix the `submit` lane before you run it.** `Fastfile:265` selects the build to attach
   with:
   ```ruby
   valid_build = builds.find { |b| b.processing_state == "VALID" }
   ```
   But `beta` passes `skip_waiting_for_build_processing: true` (`Fastfile:222`), so it
   returns before the new build finishes processing — while stale build `2605221844` is
   still `VALID`. On iteration 0 the lane will happily attach the expired May build. Add
   `&& !b.expired`, or match on the new build number explicitly.

4. **App Privacy → "Data Not Collected" → Publish.** Dashboard only, ~1 minute, needs your
   interactive login. This is the step that killed the project.
   https://appstoreconnect.apple.com/apps/6757726140/distribution/privacy

5. **Clear the IAP `MISSING_METADATA` states.** All four `prune_*` products still show
   `MISSING_METADATA`. `README_LAUNCH.md` predicted Apple would auto-flip them to
   `READY_TO_SUBMIT` once a build was associated — that didn't happen. Budget 20 min; this
   is the one item that could surprise you. **Diagnostic shortcut:** the orphan
   `com.isotropic.prune.monthly` shows `READY_TO_SUBMIT` while `prune_lifetime` shows
   `MISSING_METADATA`, and both are non-consumables. Open those two side by side in the
   dashboard — whatever field differs is your answer, and it'll almost certainly apply to
   the three subscriptions too.

6. **Delete the two orphan legacy IAPs** — `com.isotropic.prune.monthly` and
   `com.isotropic.prune.subs.monthly`. Cosmetic, but they don't match the `prune_*` IDs the
   app loads. 2 minutes.

7. **Attach build → Add for Review → Submit.** The `submit` lane you wrote on May 22
   automates the attach-and-submit; it just never got to run.

---

## 4. Is it worth it? The honest market read

**The category is real money.** Swipewipe — the app Prune clones — is estimated by
third-party trackers at roughly 400k downloads and ~$1M/month revenue as of March 2026,
against 12.5M+ lifetime downloads.

**But that outcome is not reproducible via ASO.** Swipewipe got there by going viral on
TikTok with Gen Z, and was acquired by French publisher MWM in June 2024. So the ~$1M/mo
figure is *post-acquisition, publisher-marketed* revenue — nearly two years of a
professional publisher's budget behind a listing that had already gone viral. The revenue
is downstream of a viral moment plus marketing spend, not downstream of good keywords.

That's the crux for your specific question. BibleBuddy earned ~$100 on ASO alone because
"Bible stories for kids" is a *low-competition* niche where a decent listing can rank.
"Photo cleaner" is close to the most contested utility keyword set on the store — Clever
Cleaner, CleanMy®Phone, Favvy, Cleanup, Hyper Cleaner, Swipewipe all fighting for it, most
with ad spend. **The $100 result does not transfer.** Expect meaningfully less organic
pickup than BibleBuddy got, not more.

To the broader question — yes, people still download and pay for random apps in 2026; the
category data above proves it. But the honest median for a solo dev is under $1,000/month
per app, and the top-quartile solo outcome ($3–15k/mo) generally takes 12–18 months of
sustained work on a tightly-positioned niche. Six-figure outcomes pair strong ASO with a
viral moment. That's the shape of the bet.

**Where Prune is thin.** The three things every category leader leads with, Prune doesn't
have:
- **No duplicate detection.** No similar-photo grouping either. This is the #1 advertised
  feature in the category and the main reason people install these apps.
- **Videos aren't sorted by size.** `PhotoLibraryService.swift:128` sorts the Videos feed
  by `creationDate` — but the card's subtitle says "Large files." Videos are where storage
  actually is, so this is both a false promise and a missed hook. Cheap to fix
  (`PHAssetResource` for file size, then sort descending).
- **"All Photos" silently excludes videos.** The `.recents` predicate is
  `mediaType = image`. Your headline feed can't touch the biggest files on the device.

**Pricing risk.** $6.99/week, with every category except "All Photos" behind the paywall
and 50 free swipes/day, is exactly the pattern Apple scrutinizes hardest — weekly
subscriptions on a task users perform a handful of times. Not a blocker, but budget for a
rejection round. Ready fallback: drop the weekly tier, lead with yearly + lifetime.

---

## 5. Recommendation

**Ship v1.0 as-is.** The marginal cost is one evening — a device smoke test plus dashboard
work — against an app
that is already built, tested, uploaded, and fully described. Leaving it at
`PREPARE_FOR_SUBMISSION` is strictly worse than submitting — a live listing costs nothing
to maintain and generates real impression data you cannot get any other way.

**Then gate.** Before investing the 2–4 weeks that duplicate + similar-photo detection
would take, check App Store Connect's impressions and product-page views at ~30 days:

- **Meaningful organic impressions** → build duplicate detection, fix the video sort, fix
  the All Photos predicate. You've found a keyword position worth defending.
- **Flat, near-zero impressions** → stop. The listing stays up as a free lottery ticket,
  and the honest lesson is that a straight clone can't out-ASO a saturated category.
  Redirect the effort to `nexusgto`/`poker-solver`, which is where your recent attention
  actually went.

**The one structural lesson worth keeping.** This project didn't fail on ambition or on
code. It failed at a step that could not be automated, in an automated session, and nobody
came back to do the 60 seconds of manual work. When you next drive a launch through an
agent, make the non-automatable Apple steps an explicit checklist item up front — they're
the only real bottleneck in the whole pipeline.
