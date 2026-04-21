import SwiftUI
import Photos
import Combine
import AVKit

@MainActor
final class SwipeViewModel: ObservableObject {
    private let feedType: FeedType
    private let photoService = PhotoLibraryService.shared
    private let purchaseService = PurchaseService.shared
    private let seenPhotosService = SeenPhotosService.shared
    private let gateService = SwipeGateService.shared

    enum SwipeDirection { case left, right }

    @Published var assets: [PHAsset] = []
    @Published var currentIndex: Int = 0
    @Published var isLoading: Bool = false
    @Published var pendingDeletes: Set<String> = []
    @Published var lastUndoDirection: SwipeDirection = .left
    @Published var isUndoing: Bool = false

    // Caches
    @Published var imageCache: [String: UIImage] = [:]
    @Published var videoItemCache: [String: AVPlayerItem] = [:]

    // Gate UI signal
    @Published var gateReached: Bool = false

    var currentAsset: PHAsset? {
        guard currentIndex < assets.count else { return nil }
        return assets[currentIndex]
    }

    private var swipeHistory: [SwipeDirection] = []

    var isFinished: Bool {
        return !assets.isEmpty && currentIndex >= assets.count
    }

    init(feedType: FeedType) {
        self.feedType = feedType
    }

    // MARK: - Loading

    func loadAssets() async {
        print("[SwipeViewModel] Loading assets for \(feedType)...")
        isLoading = true
        let seenIds = seenPhotosService.allSeenIds()
        let fetched = await photoService.fetchAssets(for: feedType, excludingSeen: seenIds)
        self.assets = fetched

        // Preload the first few
        if !assets.isEmpty {
            let preloadCount = min(3, assets.count)
            await withTaskGroup(of: Void.self) { group in
                for i in 0..<preloadCount {
                    let asset = assets[i]
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

        isLoading = false
        print("[SwipeViewModel] Loaded \(assets.count) assets.")
        AnalyticsService.shared.logFeedOpened(type: "\(feedType)")

        prefetch()
    }

    // MARK: - Caching

    func loadImage(for asset: PHAsset) async {
        let manager = PHCachingImageManager.default()
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false

        manager.requestImage(for: asset,
                             targetSize: CGSize(width: 600, height: 800),
                             contentMode: .aspectFill,
                             options: options) { [weak self] image, _ in
            guard let self = self, let image = image else { return }
            self.imageCache[asset.localIdentifier] = image
        }
    }

    private func loadVideoItem(for asset: PHAsset) async -> AVPlayerItem? {
        await withCheckedContinuation { continuation in
            let options = PHVideoRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            PHCachingImageManager.default().requestPlayerItem(forVideo: asset, options: options) { item, _ in
                continuation.resume(returning: item)
            }
        }
    }

    func prefetch() {
        guard !assets.isEmpty, currentIndex < assets.count else { return }
        let end = min(currentIndex + 3, assets.count - 1)
        guard currentIndex <= end else { return }
        for i in currentIndex...end {
            let asset = assets[i]
            if imageCache[asset.localIdentifier] == nil {
                Task { await loadImage(for: asset) }
            }
            if asset.mediaType == .video && videoItemCache[asset.localIdentifier] == nil {
                Task {
                    if let item = await loadVideoItem(for: asset) {
                        await MainActor.run {
                            self.videoItemCache[asset.localIdentifier] = item
                        }
                    }
                }
            }
        }
    }

    // MARK: - Swipe actions

    /// Returns true if the swipe was accepted; false if we hit the free gate.
    @discardableResult
    func swipedRight() -> Bool {
        guard let asset = currentAsset else { return false }
        if !checkAndRecordGate() { return false }

        isUndoing = false
        AnalyticsService.shared.logSwipe(keep: true, feedType: "\(feedType)")
        seenPhotosService.markAsSeen(asset.localIdentifier)
        swipeHistory.append(.right)
        advance()
        return true
    }

    @discardableResult
    func swipedLeft() -> Bool {
        guard let asset = currentAsset else { return false }
        if !checkAndRecordGate() { return false }

        isUndoing = false
        AnalyticsService.shared.logSwipe(keep: false, feedType: "\(feedType)")
        pendingDeletes.insert(asset.localIdentifier)
        seenPhotosService.markAsSeen(asset.localIdentifier)
        swipeHistory.append(.left)
        advance()
        return true
    }

    /// Returns true if the swipe should proceed; false if the free gate is exhausted.
    /// Records a swipe for free users.
    private func checkAndRecordGate() -> Bool {
        if purchaseService.isPro { return true }
        if gateService.isExhausted() {
            gateReached = true
            AnalyticsService.shared.logPaywallShown(source: "swipe_gate")
            return false
        }
        gateService.recordSwipe()
        return true
    }

    private func advance() {
        currentIndex += 1
        prefetch()
    }

    func undo() {
        guard currentIndex > 0 else { return }
        isUndoing = true

        if let last = swipeHistory.last {
            lastUndoDirection = last
            swipeHistory.removeLast()
        }

        currentIndex -= 1
        let restored = assets[currentIndex]
        if pendingDeletes.contains(restored.localIdentifier) {
            pendingDeletes.remove(restored.localIdentifier)
        }
        seenPhotosService.markAsUnseen(restored.localIdentifier)

        // Refund the gate count so undo doesn't drain the free allowance.
        if !purchaseService.isPro {
            gateService.rollbackSwipe()
        }

        AnalyticsService.shared.logUndo()
    }

    func toggleFavorite() {
        guard let asset = currentAsset else { return }
        PHPhotoLibrary.shared().performChanges {
            let request = PHAssetChangeRequest(for: asset)
            request.isFavorite = !asset.isFavorite
        } completionHandler: { success, error in
            if !success { print("Error toggling favorite: \(String(describing: error))") }
        }
    }

    // MARK: - Commit

    /// Returns (count, approxBytesFreed). `nil` if nothing committed.
    @discardableResult
    func commitDeletes() async -> (Int, Int64)? {
        guard !pendingDeletes.isEmpty else { return nil }
        let toDelete = assets.filter { pendingDeletes.contains($0.localIdentifier) }
        let approxBytes = Self.estimatedBytes(for: toDelete)
        let count = toDelete.count

        do {
            try await photoService.deleteAssets(toDelete)
            AnalyticsService.shared.logCommitDelete(count: count, estimatedMB: Double(approxBytes) / 1_048_576.0)
            return (count, approxBytes)
        } catch {
            print("Error deleting: \(error)")
            return nil
        }
    }

    /// Quick, non-blocking estimate: 3 MB for photos, 25 MB for videos.
    nonisolated static func estimatedBytes(for assets: [PHAsset]) -> Int64 {
        let photoAvg: Int64 = 3 * 1_048_576
        let videoAvg: Int64 = 25 * 1_048_576
        return assets.reduce(0) { total, asset in
            total + (asset.mediaType == .video ? videoAvg : photoAvg)
        }
    }
}
