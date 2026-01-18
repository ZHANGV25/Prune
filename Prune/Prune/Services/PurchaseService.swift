import Foundation
import StoreKit
import Combine
import RevenueCat

@MainActor
class PurchaseService: NSObject, ObservableObject {
    static let shared = PurchaseService()
    
    @Published var isPro: Bool = false
    @Published var customerInfo: CustomerInfo?
    @Published var currentOffering: Offering?
    
    private override init() {
        super.init()
        // Cache backup
         self.isPro = UserDefaults.standard.bool(forKey: "isPro_cached")
    }
    
    func configure() {
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: "test_vUZXRnxlzkFvRNLCafoRXltXvgC")
        
        Purchases.shared.delegate = self
        
        // Listen to Customer Info changes
        Purchases.shared.getCustomerInfo { [weak self] info, error in
            if let info = info {
                self?.updateStatus(with: info)
            }
        }
        
        // Fetch Offerings
        Purchases.shared.getOfferings { [weak self] offerings, error in
            if let offerings = offerings {
                self?.currentOffering = offerings.current
                print("[PurchaseService] Loaded offering: \(offerings.current?.identifier ?? "None")")
            } else if let error = error {
                print("[PurchaseService] Error fetching offerings: \(error.localizedDescription)")
            }
        }
    }
    
    func updateStatus(with info: CustomerInfo) {
        self.customerInfo = info
        // Check "Prune Pro" entitlement (Must match RevenueCat Dashboard)
        let isActive = info.entitlements["Prune Pro"]?.isActive == true
        
        // Update State
        self.isPro = isActive
        UserDefaults.standard.set(isActive, forKey: "isPro_cached")
        
        print("[PurchaseService] User is Pro: \(isActive)")
    }
    
    func purchase(package: Package) async throws {
        let result = try await Purchases.shared.purchase(package: package)
        updateStatus(with: result.customerInfo)
    }
    
    func restorePurchases() async {
        do {
            let info = try await Purchases.shared.restorePurchases()
            updateStatus(with: info)
        } catch {
            print("[PurchaseService] Restore failed: \(error)")
        }
    }
}

extension PurchaseService: PurchasesDelegate {
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        updateStatus(with: customerInfo)
    }
}
