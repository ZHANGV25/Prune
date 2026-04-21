import SwiftUI

@main
struct PruneApp: App {
    @StateObject var photoService = PhotoLibraryService.shared
    @StateObject var purchaseService = PurchaseService.shared

    init() {
        PurchaseService.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
        }
    }
}
