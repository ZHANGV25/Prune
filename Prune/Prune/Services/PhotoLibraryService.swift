import SwiftUI
import Photos
import CoreLocation
import Combine

enum FeedType: Hashable {
    case recents
    case timeframe(String) // e.g., "Today", "Last 7 Days"
    case selfies
    case screenshots
    case videos
    case favorites
    case dateRange(Date, Date)
}

@MainActor
class PhotoLibraryService: ObservableObject {
    // ... (shared, properties)
    static let shared = PhotoLibraryService()
    
    @Published var permissionStatus: PHAuthorizationStatus = .notDetermined
    @Published var isLimited: Bool = false
    
    // Caching
    let imageManager = PHCachingImageManager()
    
    private init() {
        checkStatus()
    }
    
    func checkStatus() {
        let level: PHAccessLevel = .readWrite
        let status = PHPhotoLibrary.authorizationStatus(for: level)
        self.permissionStatus = status
        self.isLimited = status == .limited
    }
    
    func requestAuthorization() async -> PHAuthorizationStatus {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        self.permissionStatus = status
        self.isLimited = status == .limited
        return status
    }
    
    nonisolated func fetchAssets(for feed: FeedType, excludingSeen: Set<String> = []) async -> [PHAsset] {
        return await Task.detached(priority: .userInitiated) {
            var result: [PHAsset] = []
            
            print("[PhotoService] Starting fetch for \(feed)...")
            switch feed {
            case .recents:
                let options = PHFetchOptions()
                options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                options.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
                let allAssets = PHAsset.fetchAssets(with: options)
                
                var count = 0
                allAssets.enumerateObjects { asset, _, stop in
                    result.append(asset)
                    count += 1

                }
                
            case .timeframe(let frame):
                let options = PHFetchOptions()
                options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                options.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
                let allAssets = PHAsset.fetchAssets(with: options)
                
                let now = Date()
                let calendar = Calendar.current
                var count = 0
                allAssets.enumerateObjects { asset, _, stop in
                    guard let date = asset.creationDate else { return }
                    if Self.does(date, match: frame, using: calendar, now: now) {
                        result.append(asset)
                        count += 1
                    }

                }
                
            case .selfies:
                // Fetch Smart Album for Selfies
                let collections = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumSelfPortraits, options: nil)
                if let collection = collections.firstObject {
                    let options = PHFetchOptions()
                    options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                    let assets = PHAsset.fetchAssets(in: collection, options: options)
                    
                    var count = 0
                    assets.enumerateObjects { asset, _, stop in
                        result.append(asset)
                        count += 1
    
                    }
                }
                print("[PhotoService] Fetched \(result.count) selfies.")
                
            case .screenshots:
                let screenshotOptions = PHFetchOptions()
                screenshotOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                screenshotOptions.predicate = NSPredicate(format: "mediaType = %d AND (mediaSubtype & %d) != 0", PHAssetMediaType.image.rawValue, PHAssetMediaSubtype.photoScreenshot.rawValue)
                
                let screenshotAssets = PHAsset.fetchAssets(with: screenshotOptions)
                var count = 0
                screenshotAssets.enumerateObjects { asset, _, stop in
                    result.append(asset)
                    count += 1

                }
            case .dateRange(let start, let end):
                let options = PHFetchOptions()
                options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                options.predicate = NSPredicate(
                    format: "mediaType = %d AND creationDate >= %@ AND creationDate <= %@",
                    PHAssetMediaType.image.rawValue,
                    start as NSDate,
                    end as NSDate
                )
                
                let rangeAssets = PHAsset.fetchAssets(with: options)
                var count = 0
                rangeAssets.enumerateObjects { asset, _, stop in
                    result.append(asset)
                    count += 1

                }
                print("[PhotoService] Fetched \(result.count) assets for date range.")

            case .videos:
                let videoOptions = PHFetchOptions()
                videoOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                videoOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
                
                let videoAssets = PHAsset.fetchAssets(with: videoOptions)
                var count = 0
                videoAssets.enumerateObjects { asset, _, stop in
                    result.append(asset)
                    count += 1

                }

            case .favorites:
                let favOptions = PHFetchOptions()
                favOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                favOptions.predicate = NSPredicate(format: "isFavorite = YES")
                
                let favAssets = PHAsset.fetchAssets(with: favOptions)
                var count = 0
                favAssets.enumerateObjects { asset, _, stop in
                    result.append(asset)
                    count += 1

                }
            }
            
            // Filter out previously seen photos
            if !excludingSeen.isEmpty {
                let beforeCount = result.count
                result = result.filter { !excludingSeen.contains($0.localIdentifier) }
                print("[PhotoService] Filtered out \(beforeCount - result.count) seen photos, \(result.count) remaining.")
            }
            
            return result
        }.value
    }
    
    nonisolated private static func does(_ date: Date, match frame: String, using calendar: Calendar, now: Date) -> Bool {
        switch frame {
        case "Today":
            return calendar.isDateInToday(date)
        case "Yesterday":
            return calendar.isDateInYesterday(date)
        case "Last 7 Days":
            guard let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now) else { return false }
            return date >= sevenDaysAgo
        case "Last 30 Days":
            guard let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now) else { return false }
            return date >= thirtyDaysAgo
        case "Older":
            guard let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now) else { return false }
            return date < thirtyDaysAgo
        default:
            return true
        }
    }
    
    func deleteAssets(_ assets: [PHAsset]) async throws {
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.deleteAssets(assets as NSArray)
        }
    }
    
    // Note: True "Undo" in Photos framework is tricky because once deleted, it goes to "Recently Deleted".
    // We can't programmatically "un-delete" from Recently Deleted without user interaction strictly speaking,
    // usually we just stop the deletion from happening if it's "queued".
    // However, the requirement says "Undo last swipe".
    // So "Deletion" should probably happen only when the session ends or user explicitly "Commits".
    // OR we delete immediately and "Undo" means we rely on the fact that we can't easily bring it back?
    // standard Tinder-style apps usually "queue" actions until a session end or have a "trash can".
    // BUT requirement says: "Deletions must use PHPhotoLibrary.performChanges deletion APIs."
    // And "Provide Undo last swipe".
    // Strategy: We will queue deletions in memory. "Keep" does nothing. "Delete" adds to `deletedAssets` set.
    // "Undo" removes from `deletedAssets` set.
    // We commit the actual PHPhotoLibrary changes periodically or on exit/background.
}
