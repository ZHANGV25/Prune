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
        print("[AdMob DEBUG] Initializing MobileAds SDK...")
        MobileAds.shared.start { status in
            print("[AdMob DEBUG] SDK initialized with status: \(status.adapterStatusesByClassName)")
        }
    }
    
    func preloadAd() {
        // Don't fetch if we already have one
        guard nextNativeAd == nil else {
            print("[AdMob DEBUG] Skipping preload - already have a cached ad")
            return
        }
        
        print("[AdMob DEBUG] Starting ad preload...")
        
        let root = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.rootViewController
        
        print("[AdMob DEBUG] Root view controller: \(String(describing: root))")
        
        // Test Ad Unit ID for Native Advanced
        let adUnitID = "ca-app-pub-3940256099942544/3986624511"
        print("[AdMob DEBUG] Using Ad Unit ID: \(adUnitID)")
        
        adLoader = AdLoader(
            adUnitID: adUnitID,
            rootViewController: root,
            adTypes: [.native],
            options: []
        )
        adLoader?.delegate = self
        
        print("[AdMob DEBUG] Calling adLoader.load()...")
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
        print("[AdMob DEBUG] ========== RECEIVED NATIVE AD ==========")
        print("[AdMob DEBUG] Headline: \(nativeAd.headline ?? "nil")")
        print("[AdMob DEBUG] Body: \(nativeAd.body ?? "nil")")
        print("[AdMob DEBUG] Call to Action: \(nativeAd.callToAction ?? "nil")")
        print("[AdMob DEBUG] Advertiser: \(nativeAd.advertiser ?? "nil")")
        print("[AdMob DEBUG] Icon present: \(nativeAd.icon != nil)")
        print("[AdMob DEBUG] Icon image: \(String(describing: nativeAd.icon?.image))")
        print("[AdMob DEBUG] Media content: \(nativeAd.mediaContent)")
        print("[AdMob DEBUG] Media aspect ratio: \(nativeAd.mediaContent.aspectRatio)")
        print("[AdMob DEBUG] Media has video: \(nativeAd.mediaContent.hasVideoContent)")
        print("[AdMob DEBUG] Star rating: \(String(describing: nativeAd.starRating))")
        print("[AdMob DEBUG] Store: \(nativeAd.store ?? "nil")")
        print("[AdMob DEBUG] Price: \(nativeAd.price ?? "nil")")
        print("[AdMob DEBUG] ============================================")
        self.nextNativeAd = nativeAd
    }
    
    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        print("[AdMob DEBUG] ========== AD LOAD FAILED ==========")
        print("[AdMob DEBUG] Error: \(error.localizedDescription)")
        print("[AdMob DEBUG] Full error: \(error)")
        print("[AdMob DEBUG] ============================================")
    }
}
