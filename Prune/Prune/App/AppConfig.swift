import Foundation

enum AppConfig {
    // TODO(launch): replace with production public SDK key from RevenueCat dashboard.
    // Public SDK key (safe to ship in-app). Find at app.revenuecat.com > Project Settings > API keys > Apple.
    static let revenueCatAPIKey = "test_vUZXRnxlzkFvRNLCafoRXltXvgC"

    // Entitlement identifier configured in RevenueCat. Must match dashboard exactly.
    static let proEntitlementID = "pro"

    // TODO(launch): point at real URLs before submission.
    static let termsOfUseURL = URL(string: "https://zhangv25.github.io/Prune/terms")!
    static let privacyPolicyURL = URL(string: "https://zhangv25.github.io/Prune/privacy")!
    static let supportURL = URL(string: "https://zhangv25.github.io/Prune/support")!
}
