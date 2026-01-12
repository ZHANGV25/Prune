import SwiftUI
import RevenueCat
import RevenueCatUI

struct PaywallView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        RevenueCatUI.PaywallView(displayCloseButton: true)
            .onPurchaseCompleted { info in
                print("Purchase completed: \(info.entitlements)")
                dismiss()
            }
            .onRestoreCompleted { info in
                print("Restore completed: \(info.entitlements)")
                // dismiss() // Optional: dismiss on restore too?
            }
    }
}
