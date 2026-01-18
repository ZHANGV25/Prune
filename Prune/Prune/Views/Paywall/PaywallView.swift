import SwiftUI
import RevenueCat
import RevenueCatUI

struct PaywallView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        CustomPaywallView()
    }
}
