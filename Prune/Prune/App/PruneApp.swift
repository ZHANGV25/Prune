import SwiftUI
// import FirebaseCore

import GoogleMobileAds

@main
struct PruneApp: App {
    @StateObject var photoService = PhotoLibraryService.shared
    @StateObject var purchaseService = PurchaseService.shared
    
    init() {
        // FirebaseApp.configure()
        PurchaseService.shared.configure()
        AdMobService.shared.initialize()
    }
    
    var body: some Scene {
        WindowGroup {
            HomeView()
                .preferredColorScheme(.dark) // Force dark mode for that premium liquid feel
        }
    }
}
