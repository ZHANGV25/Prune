import SwiftUI
import Photos

@MainActor
class SwipeViewModel: ObservableObject {
    private let feedType: FeedType
    private let photoService = PhotoLibraryService.shared
    
    @Published var assets: [PHAsset] = []
    @Published var currentIndex: Int = 0
    @Published var pendingDeletes: Set<String> = [] // LocalIdentifiers
    @Published var deletionHistory: [String] = [] // For Undo
    
    // Exposed for View to drive UI if needed, or View can handle gesture state locally 
    // and just tell VM "swiped left/right".
    // For MVVM, usually View handles the gesture math (UI) and tells VM the intent (Logic).
    
    var currentAsset: PHAsset? {
        guard currentIndex < assets.count else { return nil }
        return assets[currentIndex]
    }
    
    var nextAsset: PHAsset? {
        guard currentIndex + 1 < assets.count else { return nil }
        return assets[currentIndex + 1]
    }
    
    var isFinished: Bool {
        return !assets.isEmpty && currentIndex >= assets.count
    }
    
    init(feedType: FeedType) {
        self.feedType = feedType
    }
    
    func loadAssets() {
        self.assets = photoService.fetchAssets(for: feedType)
        AnalyticsService.shared.logFeedOpened(type: "\(feedType)")
    }
    
    func swipedRight() {
        // Keep
        AnalyticsService.shared.logSwipe(keep: true, feedType: "\(feedType)")
        advance()
    }
    
    func swipedLeft() {
        // Delete
        guard let asset = currentAsset else { return }
        AnalyticsService.shared.logSwipe(keep: false, feedType: "\(feedType)")
        pendingDeletes.insert(asset.localIdentifier)
        deletionHistory.append(asset.localIdentifier)
        advance()
    }
    
    private func advance() {
        currentIndex += 1
    }
    
    func undo() {
        guard currentIndex > 0 else { return }
        
        let prevIndex = currentIndex - 1
        let prevAsset = assets[prevIndex]
        
        if pendingDeletes.contains(prevAsset.localIdentifier) {
            pendingDeletes.remove(prevAsset.localIdentifier)
            if let last = deletionHistory.last, last == prevAsset.localIdentifier {
                deletionHistory.removeLast()
            }
        }
        
        currentIndex = prevIndex
        AnalyticsService.shared.logUndo()
    }
    
    func commitDeletes() async {
        guard !pendingDeletes.isEmpty else { return }
        let toDelete = assets.filter { pendingDeletes.contains($0.localIdentifier) }
        
        do {
            try await photoService.deleteAssets(toDelete)
            // Could clear pendingDeletes here or just rely on dismissal
        } catch {
            print("Error deleting: \(error)")
        }
    }
}
