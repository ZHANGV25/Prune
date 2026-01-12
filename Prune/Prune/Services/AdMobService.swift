import Foundation
import GoogleMobileAds
import UIKit
import Combine

class AdMobService: NSObject, ObservableObject {
    static let shared = AdMobService()
    
    private var adLoader: AdLoader?
    
    // Cache for a preloaded ad
    @Published var nextNativeAd: NativeAd?
    
    override init() {
        super.init()
    }
    
    func initialize() {
        MobileAds.shared.start(completionHandler: nil)
    }
    
    func preloadAd() {
        // Don't fetch if we already have one
        guard nextNativeAd == nil else { return }
        
        let root = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.rootViewController
        
        // Test Ad Unit ID for Native Advanced
        let adUnitID = "ca-app-pub-3940256099942544/3986624511"
        
        adLoader = AdLoader(
            adUnitID: adUnitID,
            rootViewController: root,
            adTypes: [.native],
            options: []
        )
        adLoader?.delegate = self
        
        adLoader?.load(Request())
    }
    
    // Called when a card consumes the ad
    func consumeAd() -> NativeAd? {
        let ad = nextNativeAd
        nextNativeAd = nil
        preloadAd() // Fetch the next one
        return ad
    }
}

extension AdMobService: NativeAdLoaderDelegate {
    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        print("AdMob: Received Native Ad")
        self.nextNativeAd = nativeAd
    }
    
    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        print("AdMob: Failed to receive ad - \(error.localizedDescription)")
    }
}
