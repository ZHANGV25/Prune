import SwiftUI
import RevenueCat

struct CustomPaywallView: View {
    @ObservedObject var service = PurchaseService.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header
                Spacer()
                
                Image(systemName: "crown.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .padding(.bottom, 10)
                
                Text("Pruned Pro")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                
                Text("Unlock the full potential of your photo library.")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Features
                VStack(alignment: .leading, spacing: 15) {
                    FeatureRow(icon: "camera.viewfinder", text: "Clean Screenshots & Selfies")
                    FeatureRow(icon: "play.rectangle.fill", text: "Manage Large Videos")
                    FeatureRow(icon: "calendar", text: "Filter by Date Range")
                    FeatureRow(icon: "nosign", text: "No Ads")
                }
                .padding(.vertical, 30)
                
                Spacer()
                
                // Packages
                if let offering = service.currentOffering {
                    VStack(spacing: 12) {
                        ForEach(offering.availablePackages) { package in
                            Button {
                                Task {
                                    do {
                                        try await service.purchase(package: package)
                                        dismiss()
                                    } catch {
                                        print("Purchase failed: \(error)")
                                    }
                                }
                            } label: {
                                PackageButton(package: package)
                            }
                        }
                    }
                } else {
                    ProgressView()
                        .tint(.white)
                }
                
                Spacer()
                
                // Footer
                HStack(spacing: 20) {
                    Button("Restore Purchases") {
                        Task {
                            await service.restorePurchases()
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                    
                    Button("Terms & Privacy") {
                        // Open URL
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                }
                .padding(.bottom, 20)
            }
            .padding()
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue) // Prune primary color?
            Text(text)
                .foregroundColor(.white)
            Spacer()
        }
        .font(.title3)
        .padding(.horizontal, 40)
    }
}

struct PackageButton: View {
    let package: Package
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(package.storeProduct.subscriptionPeriod?.durationTitle ?? "Lifetime")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            Spacer()
            
            Text(package.localizedPriceString)
                .font(.headline)
                .foregroundColor(.white)
        }
        .padding()
        .background(Color(white: 0.15))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

extension SubscriptionPeriod {
    var durationTitle: String {
        switch unit {
        case .day: return "Daily"
        case .week: return "Weekly"
        case .month: return "Monthly"
        case .year: return "Yearly"
        @unknown default: return "Unknown"
        }
    }
}
