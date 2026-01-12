import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var purchaseService = PurchaseService.shared
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // "Glass" background effect
            LinearGradient(colors: [.blue.opacity(0.3), .purple.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding()
                
                Spacer()
                
                Image(systemName: "sparkles")
                    .font(.system(size: 80))
                    .foregroundColor(.yellow)
                    .shadow(color: .yellow.opacity(0.5), radius: 20)
                
                Text("Unlock Prune Pro")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 16) {
                    FeatureRow(text: "Unlimited Swipes (Included in Free)")
                        .opacity(0.6) // Show what they already have vs new? Or just list Pro benefits
                    FeatureRow(text: "Group by Time (Today, Last Week)")
                    FeatureRow(text: "Group by Location")
                    FeatureRow(text: "Support Future Development")
                    FeatureRow(text: "Offline-First Design")
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(20)
                .padding(.horizontal)
                
                Spacer()
                
                VStack(spacing: 12) {
                    Text("Lifetime Unlock")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .textCase(.uppercase)
                    
                    Button(action: {
                        Task { await purchaseService.purchasePro() }
                    }) {
                        Text("Unlock for \(purchaseService.priceString)")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(30)
                    }
                    .padding(.horizontal)
                    
                    Button("Restore Purchases") {
                        Task { await purchaseService.restorePurchases() }
                    }
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.7))
                }
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            AnalyticsService.shared.log("paywall_shown", params: ["source": "feed_lock"])
        }
    }
}

struct FeatureRow: View {
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text(text)
                .foregroundColor(.white)
                .font(.body)
        }
    }
}
