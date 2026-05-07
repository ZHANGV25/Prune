import Foundation
import StoreKit
import Combine

@MainActor
final class PurchaseService: ObservableObject {
    static let shared = PurchaseService()

    @Published private(set) var isPro: Bool = false
    @Published private(set) var products: [Product] = []

    static let productIDs = [
        "prune_weekly",
        "prune_monthly",
        "prune_yearly",
        "prune_lifetime",
    ]

    private static let cacheKey = "isPro_cached"
    private static let order = Dictionary(uniqueKeysWithValues: productIDs.enumerated().map { ($1, $0) })

    private var updatesTask: Task<Void, Never>?

    private init() {
        isPro = UserDefaults.standard.bool(forKey: Self.cacheKey)
    }

    func configure() {
        updatesTask?.cancel()
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                await self?.handle(result)
            }
        }
        Task { await loadProducts() }
        Task { await refreshEntitlements() }
    }

    func loadProducts() async {
        do {
            let fetched = try await Product.products(for: Self.productIDs)
            self.products = fetched.sorted { (Self.order[$0.id] ?? 99) < (Self.order[$1.id] ?? 99) }
        } catch {
            print("[PurchaseService] product load failed: \(error)")
        }
    }

    func refreshEntitlements() async {
        var active = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let txn) = result, Self.productIDs.contains(txn.productID) else { continue }
            if let revoked = txn.revocationDate, revoked <= Date() { continue }
            if let expires = txn.expirationDate, expires <= Date() { continue }
            active = true
        }
        self.isPro = active
        UserDefaults.standard.set(active, forKey: Self.cacheKey)
    }

    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            await handle(verification)
        case .userCancelled, .pending:
            break
        @unknown default:
            break
        }
    }

    func restore() async {
        do {
            try await AppStore.sync()
        } catch {
            print("[PurchaseService] restore failed: \(error)")
        }
        await refreshEntitlements()
    }

    private func handle(_ verification: VerificationResult<Transaction>) async {
        guard case .verified(let txn) = verification else { return }
        await refreshEntitlements()
        await txn.finish()
    }
}
