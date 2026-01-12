import SwiftUI
// import FirebaseCore

@main
struct PruneApp: App {
    @StateObject var photoService = PhotoLibraryService.shared
    @StateObject var purchaseService = PurchaseService.shared
    
    init() {
        // FirebaseApp.configure()
        PurchaseService.shared.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            HomeView()
                .preferredColorScheme(.dark) // Force dark mode for that premium liquid feel
        }
    }
}
