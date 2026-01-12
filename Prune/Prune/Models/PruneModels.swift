import SwiftUI
import Photos

struct Feed: Identifiable, Hashable {
    let id = UUID()
    let type: FeedType
    let title: String
    let subtitle: String?
    let iconName: String
    let isProLocked: Bool
    let color: Color
}

struct AssetItem: Identifiable, Equatable {
    let id: String // LocalIdentifier
    let asset: PHAsset
    // We can add cached image or state here if needed
}
