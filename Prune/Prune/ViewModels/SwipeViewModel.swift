import SwiftUI
import Photos
import Combine
import AVKit
import GoogleMobileAds

@MainActor
class SwipeViewModel: ObservableObject {
    private let feedType: FeedType
    private let photoService = PhotoLibraryService.shared
    private let purchaseService = PurchaseService.shared
    private let adService = AdMobService.shared
    private let seenPhotosService = SeenPhotosService.shared
    private var cancellables = Set<AnyCancellable>()
    
    enum SwipeDirection {
        case left
        case right
    }
    
    // items in deck
    enum DeckItem: Identifiable, Hashable {
        case photo(PHAsset)
        case ad(id: UUID, nativeAd: NativeAd?)
        
        var id: String {
            switch self {
            case .photo(let asset): return asset.localIdentifier
            case .ad(let id, _): return id.uuidString
            }
        }
        
        static func == (lhs: DeckItem, rhs: DeckItem) -> Bool {
            return lhs.id == rhs.id
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }

    @Published var items: [DeckItem] = []
    @Published var currentIndex: Int = 0
    @Published var isLoading: Bool = false
    @Published var pendingDeletes: Set<String> = [] // LocalIdentifiers
    @Published var lastUndoDirection: SwipeDirection = .left
    @Published var isUndoing: Bool = false
    
    // Video Preloading
    @Published var videoItemCache: [String: AVPlayerItem] = [:]
    
    // Helpers for View
    var currentItem: DeckItem? {
        guard currentIndex < items.count else { return nil }
        return items[currentIndex]
    }
    
    var currentAsset: PHAsset? {
        if case .photo(let asset) = currentItem { return asset }
        return nil
    }
    
    // Access original assets for FinishView etc (excluding ads)
    var photoAssets: [PHAsset] {
        items.compactMap { item in
            if case .photo(let asset) = item { return asset }
            return nil
        }
    }
    
    private var swipeHistory: [SwipeDirection] = []
    
    // Image Caching for smooth swiping
    @Published var imageCache: [String: UIImage] = [:]
    
    var isFinished: Bool {
        return !items.isEmpty && currentIndex >= items.count
    }
    
    init(feedType: FeedType) {
        self.feedType = feedType
        setupAdBindings()
    }
    
    func setupAdBindings() {
        adService.$nextNativeAd
            .receive(on: DispatchQueue.main)
            .sink { [weak self] ad in
                guard let self = self, let ad = ad else { return }
                self.fillNextAdSlot(with: ad)
            }
            .store(in: &cancellables)
    }
    
    func fillNextAdSlot(with ad: NativeAd) {
        // Find the first upcoming ad slot that is empty
        for i in currentIndex..<items.count {
            if case .ad(let id, let nativeAd) = items[i], nativeAd == nil {
                // Determine if we should use this ad (e.g. valid)
                // Consume it from service if not already consumed? 
                // The service emits it, but we should make sure we don't use it twice.
                // For now, assume service emits unique ads or we handle logic here.
                
                // Update item
                 items[i] = .ad(id: id, nativeAd: ad)
                
                // Clear from service so it fetches another one next time?
                // Actually, AdMobService holds it until consumed.
                // We should tell AdMobService we used it.
                _ = adService.consumeAd()
                return
            }
        }
    }
    
    func loadImage(for asset: PHAsset) async {
         let manager = PHCachingImageManager.default()
         let options = PHImageRequestOptions()
         options.deliveryMode = .highQualityFormat 
         options.isNetworkAccessAllowed = true
         options.isSynchronous = false
         
         // 600x800 is good for card size
         manager.requestImage(for: asset, targetSize: CGSize(width: 600, height: 800), contentMode: .aspectFill, options: options) { [weak self] image, _ in
             guard let self = self, let image = image else { return }
             self.imageCache[asset.localIdentifier] = image
         }
    }
    
    func prefetchImages() {
        guard !items.isEmpty, currentIndex < items.count else { return }
        
        // Prefetch current + next 3
        let start = currentIndex
        let end = min(currentIndex + 3, items.count - 1)
        
        guard start <= end else { return }
        
        let range = start...end
        for i in range {
            let item = items[i]
            switch item {
            case .photo(let asset):
                // Prefetch Image
                if imageCache[asset.localIdentifier] == nil {
                    Task { await loadImage(for: asset) }
                }
                
                // Prefetch Video
                if asset.mediaType == .video && videoItemCache[asset.localIdentifier] == nil {
                    Task {
                        if let item = await loadVideoItem(for: asset) {
                            await MainActor.run {
                                self.videoItemCache[asset.localIdentifier] = item
                            }
                        }
                    }
                }
            case .ad(_, let nativeAd):
                if nativeAd == nil {
                     // Trigger Ad Fetch
                     adService.preloadAd()
                }
            }
        }
        
        // Cleanup...
    }

    func loadAssets() async {
        print("[SwipeViewModel] Loading assets for \(feedType)...")
        isLoading = true
        let seenIds = seenPhotosService.allSeenIds()
        let fetched = await photoService.fetchAssets(for: feedType, excludingSeen: seenIds)
        
        // INTERLEAVE ADS
        var newItems: [DeckItem] = []
        let isPro = purchaseService.isPro
        let adFrequency = 4
        
        for (index, asset) in fetched.enumerated() {
            // Add Photo
            newItems.append(.photo(asset))
            
            // Insert Ad after every 4 photos if NOT Pro
            if !isPro && (index + 1) % adFrequency == 0 {
                newItems.append(.ad(id: UUID(), nativeAd: nil))
            }
        }
        
        self.items = newItems
        
        // Critical: Preload FIRST few items
        if !items.isEmpty {
            let preloadCount = min(3, items.count)
             await withTaskGroup(of: Void.self) { group in
                for i in 0..<preloadCount {
                    if case .photo(let asset) = items[i] {
                        group.addTask {
                            await self.loadImage(for: asset)
                            if asset.mediaType == .video {
                                if let item = await self.loadVideoItem(for: asset) {
                                    await MainActor.run {
                                        self.videoItemCache[asset.localIdentifier] = item
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        isLoading = false
        print("[SwipeViewModel] Loaded \(items.count) items (including ads).")
        AnalyticsService.shared.logFeedOpened(type: "\(feedType)")
        
        // Continue prefetching
        prefetchImages()
    }
    
    private func loadVideoItem(for asset: PHAsset) async -> AVPlayerItem? {
        return await withCheckedContinuation { continuation in
            let options = PHVideoRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            
            PHCachingImageManager.default().requestPlayerItem(forVideo: asset, options: options) { item, _ in
                continuation.resume(returning: item)
            }
        }
    }

    func swipedRight() {
        // Keep / Ad Dismiss
        isUndoing = false
        
        if let current = currentItem {
            switch current {
            case .photo(let asset):
                AnalyticsService.shared.logSwipe(keep: true, feedType: "\(feedType)")
                seenPhotosService.markAsSeen(asset.localIdentifier)
            case .ad(_, let nativeAd):
                print("Ad swiped right")
                // If it's a native ad, we might want to register a click if we can.
                // But typically native ads need a real tap.
            }
        }
        
        swipeHistory.append(.right)
        advance()
    }
    
    func swipedLeft() {
        // Delete / Ad Dismiss
        isUndoing = false
        
        if let current = currentItem {
            switch current {
            case .photo(let asset):
                 AnalyticsService.shared.logSwipe(keep: false, feedType: "\(feedType)")
                 pendingDeletes.insert(asset.localIdentifier)
                 seenPhotosService.markAsSeen(asset.localIdentifier)
            case .ad:
                 print("Ad swiped left")
            }
        }
        
        swipeHistory.append(.left)
        advance()
    }
    
    private func advance() {
        currentIndex += 1
        prefetchImages()
    }
    
    func undo() {
        guard currentIndex > 0 else { return }
        isUndoing = true
        
        // SKIP ADS: Recursively undo ads until we find a photo
        while currentIndex > 0, case .ad = items[currentIndex - 1] {
            currentIndex -= 1
            if !swipeHistory.isEmpty {
                swipeHistory.removeLast()
            }
        }
        
        // Now perform the actual undo for the Photo
        guard currentIndex > 0 else { return }
        
        // Capture direction BEFORE removing it
        if let last = swipeHistory.last {
            lastUndoDirection = last
            swipeHistory.removeLast()
        }
        
        // Decrement to the photo
        currentIndex -= 1
        
        let restoredItem = items[currentIndex]
        
        // If it was a photo marked for deletion, unmark it
        // Also remove from seen so it stays visible in current session
        if case .photo(let asset) = restoredItem {
            if pendingDeletes.contains(asset.localIdentifier) {
                pendingDeletes.remove(asset.localIdentifier)
            }
            seenPhotosService.markAsUnseen(asset.localIdentifier)
        }
        
        AnalyticsService.shared.logUndo()
    }
    
    func toggleFavorite() {
        guard let asset = currentAsset else { return }
        
        PHPhotoLibrary.shared().performChanges {
            let request = PHAssetChangeRequest(for: asset)
            request.isFavorite = !asset.isFavorite
        } completionHandler: { success, error in
            if success {
                print("Toggled favorite: \(asset.isFavorite)")
            } else {
                print("Error toggling favorite: \(String(describing: error))")
            }
        }
    }
    
    func commitDeletes() async {
        guard !pendingDeletes.isEmpty else { return }
        let allPhotos = items.compactMap { item -> PHAsset? in
            if case .photo(let asset) = item { return asset }
            return nil
        }
        let toDelete = allPhotos.filter { pendingDeletes.contains($0.localIdentifier) }
        
        do {
            try await photoService.deleteAssets(toDelete)
        } catch {
            print("Error deleting: \(error)")
        }
    }
}
