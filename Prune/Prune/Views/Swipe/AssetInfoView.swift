import SwiftUI
import Photos

struct AssetInfoView: View {
    let asset: PHAsset
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Photo Details")
                .font(.headline)
                .padding(.top)
            
            VStack(alignment: .leading, spacing: 12) {
                InfoRow(icon: "calendar", label: "Date", value: asset.creationDate?.formatted(date: .long, time: .shortened) ?? "Unknown")
                InfoRow(icon: "arrow.up.left.and.arrow.down.right", label: "Dimensions", value: "\(asset.pixelWidth) x \(asset.pixelHeight)")
                // Location would basically need reverse geocoding to be useful name, just showing coordinates is ugly.
                // Skipping location detail for now unless coordinate requested.
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .background(Color(.systemBackground))
    }
}

struct InfoRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 24)
            Text(label)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            Text(value)
                .bold()
            Spacer()
        }
    }
}
