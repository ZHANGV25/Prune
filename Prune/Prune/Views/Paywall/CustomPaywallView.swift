import SwiftUI
import StoreKit

struct CustomPaywallView: View {
    @ObservedObject var service = PurchaseService.shared
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 20) {
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

                VStack(alignment: .leading, spacing: 15) {
                    FeatureRow(icon: "infinity", text: "Unlimited swipes")
                    FeatureRow(icon: "camera.viewfinder", text: "Screenshots & Selfies")
                    FeatureRow(icon: "play.rectangle.fill", text: "Manage Large Videos")
                    FeatureRow(icon: "calendar", text: "Filter by Date Range")
                }
                .padding(.vertical, 30)

                Spacer()

                if service.products.isEmpty {
                    ProgressView()
                        .tint(.white)
                } else {
                    VStack(spacing: 12) {
                        ForEach(service.products, id: \.id) { product in
                            Button {
                                Task {
                                    do {
                                        try await service.purchase(product)
                                        if service.isPro { dismiss() }
                                    } catch {
                                        print("Purchase failed: \(error)")
                                    }
                                }
                            } label: {
                                ProductButton(product: product)
                            }
                        }
                    }
                }

                Spacer()

                Text("Subscriptions auto-renew until canceled. Manage or cancel in Settings > Apple ID > Subscriptions.")
                    .font(.caption2)
                    .foregroundColor(.gray.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                HStack(spacing: 20) {
                    Button("Restore Purchases") {
                        Task { await service.restore() }
                    }
                    .font(.caption)
                    .foregroundColor(.gray)

                    Link("Terms of Use", destination: AppConfig.termsOfUseURL)
                        .font(.caption)
                        .foregroundColor(.gray)

                    Link("Privacy Policy", destination: AppConfig.privacyPolicyURL)
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
                .foregroundColor(.blue)
            Text(text)
                .foregroundColor(.white)
            Spacer()
        }
        .font(.title3)
        .padding(.horizontal, 40)
    }
}

struct ProductButton: View {
    let product: Product

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(title(for: product))
                    .font(.headline)
                    .foregroundColor(.white)
            }
            Spacer()

            Text(product.displayPrice)
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

    private func title(for product: Product) -> String {
        if let period = product.subscription?.subscriptionPeriod {
            switch period.unit {
            case .day: return "Daily"
            case .week: return "Weekly"
            case .month: return "Monthly"
            case .year: return "Yearly"
            @unknown default: return product.displayName
            }
        }
        return "Lifetime"
    }
}
