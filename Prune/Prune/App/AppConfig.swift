import Foundation

enum AppConfig {
    // TODO(launch): replace with production key from RevenueCat dashboard.
    // Public SDK key (safe to ship in-app). Find at app.revenuecat.com > Project Settings > API keys > Apple.
    static let revenueCatAPIKey = "test_vUZXRnxlzkFvRNLCafoRXltXvgC"

    // Entitlement identifier configured in RevenueCat. Must match dashboard exactly.
    static let proEntitlementID = "pro"

    // TODO(launch): replace both with production IDs from AdMob.
    // Dev builds use Google's published test IDs so ads render without billing.
    #if DEBUG
    static let admobAppID = "ca-app-pub-3940256099942544~1458002511"
    static let admobNativeAdUnitID = "ca-app-pub-3940256099942544/3986624511"
    #else
    static let admobAppID = "ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX"
    static let admobNativeAdUnitID = "ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX"
    #endif

    // TODO(launch): point at real URLs before submission.
    static let termsOfUseURL = URL(string: "https://isotropicstudios.com/prune/terms")!
    static let privacyPolicyURL = URL(string: "https://isotropicstudios.com/prune/privacy")!
    static let supportURL = URL(string: "https://isotropicstudios.com/prune/support")!
}
