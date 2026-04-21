import SwiftUI
import GoogleMobileAds

@main
struct PruneApp: App {
    @StateObject var photoService = PhotoLibraryService.shared
    @StateObject var purchaseService = PurchaseService.shared

    init() {
        PurchaseService.shared.configure()
        AdMobService.shared.initialize()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
        }
    }
}
