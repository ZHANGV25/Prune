# Prune - iOS Photo Cleaner MVP

## Overview
Prune is an offline-first, fast photo cleanup tool using a Tinder-like swipe interface, built with SwiftUI and the native Photos framework.

## Project Setup

### 1. File Structure
The source code is located in the `Prune` folder.
- `App/`: `PruneApp.swift`
- `Models/`: Data models
- `Services/`: `PhotoLibraryService`, `PurchaseService`, `AnalyticsService`
- `Views/`: SwiftUI Views (`HomeView`, `SwipeDeckView`...)

### 2. Dependencies
You need to add the following Swift Packages manually in Xcode Project Settings -> Package Dependencies:

1.  **Firebase**: `https://github.com/firebase/firebase-ios-sdk`
    - Select libraries: `FirebaseAnalytics`
2.  **RevenueCat**: `https://github.com/RevenueCat/purchases-ios`
    - Select library: `RevenueCat`

### 3. Configuration
**Firebase**:
1.  Go to the Firebase Console and create a new project.
2.  Add an iOS app.
3.  Download `GoogleService-Info.plist`.
4.  Drag and drop it into the `Prune/App` folder in Xcode (Make sure "Add to targets" is checked).
5.  Uncomment `import FirebaseAnalytics` and `FirebaseApp.configure()` in `AnalyticsService.swift` and `PruneApp.swift`.

**RevenueCat**:
1.  Go to RevenueCat dashboard.
2.  Create a project and an iOS app.
3.  Get your Public API Key.
4.  Create an Entitlement called `pro`.
5.  Create an Offering with a Lifetime package (~$9.99).
6.  In `PurchaseService.swift`, uncomment `import RevenueCat` and `Purchases.configure(withAPIKey: "YOUR_KEY")` and replace with your key.

**Permissions**:
- `Info.plist` is already created with `NSPhotoLibraryUsageDescription` and `NSPhotoLibraryAddUsageDescription`.

### 4. Running the App
1.  Open Xcode.
2.  Create a new project or Open Existing if you have a `.xcodeproj` (Note: Since this code was generated, you likely need to create a "New Project" in Xcode, select "App", name it "Prune", and then drag the generated `Prune` folder into the project, deleting the default created files).
3.  **Important**: Run on a **REAL DEVICE**. The iOS Simulator does not have a real Photo Library and performance testing the swipe mechanics requires a real device.

## Architecture Notes
- **PhotoLibraryService**: Handles all direct PHAsset interactions. It caches images using `PHCachingImageManager` for smooth performance.
- **Offline First**: All feed logic runs locally. Permissions are requested on first launch.
- **Paywall**: The Paywall logic in `PurchaseService` checks `UserDefaults` for an offline backup of the entitlement status so users don't lose access if they go offline.

## Key Features
- **Recents Feed**: Default feed, sorted by creation date.
- **Smart Feeds** (Pro): Timeframes and Locations.
- **Swipe Logic**: Right to keep, Left to delete (queued).
- **Review Screen**: Confirmation before actual deletion using `PHPhotoLibrary.performChanges`.
