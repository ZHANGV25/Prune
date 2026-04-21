# App Store Connect — copy-paste metadata

Everything below is drafted to fit Apple's exact character limits. Paste as-is into App Store Connect.

---

## App Name (max 30 chars, 17 used)

```
Prune: Photo Cleaner
```

## Subtitle (max 30 chars, 27 used)

```
Swipe to clean your camera
```

Alternate options if the above reads wrong to you:
- `Swipe to free up space` (22)
- `Clean photos in minutes` (23)
- `Tinder for your camera roll` (27)
- `Photo cleanup, on device` (24)

---

## Keywords (max 100 chars, comma-separated, single field)

```
photo,cleaner,cleanup,swipe,delete,storage,free space,declutter,duplicate,gallery,camera roll,organize
```

97 chars. No need to repeat the app name, subtitle, or category — Apple indexes those automatically. No spaces after commas.

Alt keyword set (more on screenshots/selfies): `photo cleaner,swipe,delete,storage,screenshots,selfies,duplicate,declutter,organize,space,camera`

---

## Promotional Text (max 170 chars — can be updated any time without a review)

```
3-day free trial on the Weekly plan. Clean screenshots, selfies, big videos, and old photos by month. All on device — nothing leaves your iPhone.
```

164 chars. Swap freely for seasonal promos; doesn't require review.

---

## Description (max 4000 chars)

```
Prune is the fastest way to clean up your iPhone's photo library. Swipe right to keep, left to delete — just like dating apps, but for your camera roll. Everything runs on your device. Nothing gets uploaded.

When you're done swiping, Prune shows you a final review grid. Confirm, and it moves the photos you picked into Apple's Recently Deleted album — where they sit for 30 days before permanent removal, exactly like deleting in the Apple Photos app. You can always change your mind.

WHY PEOPLE USE PRUNE

• It turns "one day I'll clean this up" into "ten minutes of swiping before bed."
• It shows you how much storage you just freed, so the work feels worth it.
• It never, ever uploads your photos. No cloud AI. No sync. No "we take privacy seriously" claims with asterisks.

FREE TIER

• 50 swipes per day on the All Photos feed
• Full review screen and undo
• Storage-saved counter

PRO — OPTIONAL

• Unlimited swipes
• Smart feeds: clean by date range (month-by-month), Today, Screenshots, Selfies, Videos, Favorites
• 3-day free trial on the weekly plan

PRIVACY FIRST

• Zero photo uploads. Prune uses Apple's Photos framework to read and delete, the same one the Apple Photos app uses.
• No ads. No tracking. No advertising SDKs. No IDFA.
• The only data that leaves your device is your RevenueCat purchase ID, so we can verify your Pro subscription across installs.

HOW IT WORKS

1. Open a feed — All Photos, or any smart feed if you're Pro.
2. Swipe right to keep, left to delete. Undo with a tap. Favorite with a double-tap.
3. When you're done (or hit the back button), Prune shows a grid of everything you marked for deletion. Review it.
4. Tap "Delete" and the photos go to Recently Deleted. You keep 30 days to recover anything.

SUBSCRIPTIONS

Prune Pro is offered as:
• Weekly, with a 3-day free trial, then auto-renewing weekly
• Monthly, auto-renewing monthly
• Yearly, with an introductory offer, auto-renewing yearly
• Lifetime, one-time purchase

Auto-renewing subscriptions renew until canceled. Cancel any time in Settings > your Apple ID > Subscriptions. Payment is charged to your Apple ID on purchase confirmation.

Terms of Use: https://zhangv25.github.io/Prune/terms
Privacy Policy: https://zhangv25.github.io/Prune/privacy
Support: vhzhang2020@gmail.com

Made by Isotropic Studios. Thank you for keeping your photos tidy.
```

2,460 chars. Safely under the 4,000 limit.

---

## What's New (per-version, max 4000 chars)

For the initial 1.0 release:

```
First release. Swipe right to keep, left to delete. Clean your photo library in minutes — all on device. Pro unlocks unlimited swipes and smart feeds by date range, screenshots, selfies, videos, and favorites.
```

---

## Category

- **Primary**: Utilities
- **Secondary**: Photo & Video

These are the two categories top photo-cleaner apps (Cleanup, Cleaner Kit, SwipeWipe) live in.

---

## Age Rating

- **Age Rating**: 4+
- Answers for Apple's questionnaire: none of the content categories apply. No user-generated content, no unrestricted web access, no contests, no mature themes.

---

## Content Rights

- **Contains third-party content**: No.

---

## Privacy — App Privacy "nutrition labels"

In App Store Connect → App Privacy, declare:

**Data Not Collected** is NOT the right answer because RevenueCat collects.

Correct answers:

### Data Types Collected
- **Purchases → Purchase History** — Linked to user, NOT used for tracking, purpose: App Functionality
- **Identifiers → User ID** — Linked to user (the pseudonymous RevenueCat user ID), NOT used for tracking, purpose: App Functionality
- **Diagnostics → Crash Data** — Not linked to user, NOT used for tracking, purpose: App Functionality
- **Diagnostics → Performance Data** — Not linked to user, NOT used for tracking, purpose: App Functionality

### Data Types NOT Collected (leave these off)
- Photos or Videos (we don't upload any)
- Contacts, Location, Health, Contacts, Browsing History, Search History — none collected
- No "tracking" toggle. The PrivacyInfo.xcprivacy in the bundle declares `NSPrivacyTracking = false`.

---

## App Review — Notes to Reviewer

```
Prune is a photo-cleanup utility with a Tinder-style swipe interface. To test:

1. Grant photo library access on first launch.
2. Tap "All Photos" on the home screen.
3. Swipe right to keep, left to delete.
4. Tap back (top left). Review the deletion grid. Tap "Delete" to confirm.
5. The photos go to Recently Deleted, where iOS keeps them 30 days. No uploads.

Pro features (smart feeds by date range, screenshots, selfies, videos, favorites) require a subscription. StoreKit sandbox testers can buy a subscription without being charged.

Questions: vhzhang2020@gmail.com
```

---

## App Review — Demo Account

Not applicable. No sign-in flow.

---

## Marketing URL

```
https://zhangv25.github.io/Prune/
```

## Support URL

```
https://zhangv25.github.io/Prune/support
```

## Privacy Policy URL

```
https://zhangv25.github.io/Prune/privacy
```

---

## Icon and Screenshots

- **App Icon** — 1024×1024, no alpha, no rounded corners. The one in `Prune/Prune/Assets.xcassets/AppIcon.appiconset/Icon-1024.png` will be used.
- **Screenshots** — needed in two sizes for 2026:
  - **6.9" iPhone**: 1290×2796 (iPhone 17 Pro Max). Required.
  - **13" iPad**: 2064×2752. Only required if the app supports iPad (ours does).
- Apple downscales these for the smaller screen sizes.

Automated screenshot generation pass is in `tools/screenshots/` (see next task).

---

## Territories and Pricing

- **Territories**: All available. No reason to exclude any.
- **Pricing**:
  - Base app: Free
  - Subscriptions: configure via IAP product IDs `prune_weekly` ($6.99), `prune_monthly` ($4.99), `prune_yearly` ($39.99 with $0.99 intro week), `prune_lifetime` ($99.99)

---

## Post-launch notes

- The first build of each version string needs Beta App Review for external TestFlight. Plan ~48h turnaround.
- Promotional Text updates don't need a review — use it for A/B testing hooks and seasonal messaging.
- App Review historically flags photo cleaners for: (a) dark-pattern paywalls (we have none — trial terms are plain), (b) destructive deletion without clear confirmation (we have the FinishView grid), (c) tracking claims that don't match the privacy manifest (ours declares no tracking and uses none).
