import Foundation

/// Service to persist which photo asset IDs have been "seen" (swiped on).
/// Uses UserDefaults for simple persistence.
class SeenPhotosService {
    static let shared = SeenPhotosService()
    
    private let userDefaultsKey = "seenPhotoIdentifiers"
    
    /// In-memory cache of seen photo IDs for fast lookup
    private var seenIds: Set<String>
    
    private init() {
        // Load from UserDefaults
        if let stored = UserDefaults.standard.array(forKey: userDefaultsKey) as? [String] {
            seenIds = Set(stored)
        } else {
            seenIds = []
        }
    }
    
    /// Check if a photo has been seen
    func isSeen(_ localIdentifier: String) -> Bool {
        return seenIds.contains(localIdentifier)
    }
    
    /// Get all seen photo IDs
    func allSeenIds() -> Set<String> {
        return seenIds
    }
    
    /// Mark a photo as seen
    func markAsSeen(_ localIdentifier: String) {
        guard !seenIds.contains(localIdentifier) else { return }
        seenIds.insert(localIdentifier)
        persist()
    }
    
    /// Mark multiple photos as seen
    func markAsSeen(_ localIdentifiers: [String]) {
        let newIds = localIdentifiers.filter { !seenIds.contains($0) }
        guard !newIds.isEmpty else { return }
        seenIds.formUnion(newIds)
        persist()
    }
    
    /// Remove a photo from the seen set (for undo functionality)
    func markAsUnseen(_ localIdentifier: String) {
        guard seenIds.contains(localIdentifier) else { return }
        seenIds.remove(localIdentifier)
        persist()
    }
    
    /// Clear all seen photos (reset)
    func clearAll() {
        seenIds.removeAll()
        persist()
    }
    
    private func persist() {
        UserDefaults.standard.set(Array(seenIds), forKey: userDefaultsKey)
    }
}
