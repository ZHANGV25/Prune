import SwiftUI

struct CelebrationView: View {
    let deletedCount: Int
    let approxBytesFreed: Int64
    let onDone: () -> Void

    @State private var animateIn = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Gradient halo
            RadialGradient(
                colors: [Color.green.opacity(0.35), .clear],
                center: .center,
                startRadius: 20,
                endRadius: 400
            )
            .ignoresSafeArea()
            .opacity(animateIn ? 1 : 0)

            VStack(spacing: 32) {
                Spacer()

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 120, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .shadow(color: .green.opacity(0.5), radius: 24)
                    .scaleEffect(animateIn ? 1 : 0.3)
                    .opacity(animateIn ? 1 : 0)

                VStack(spacing: 12) {
                    Text("Nice work!")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(.white)

                    Text(savedLine)
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)

                    Text(subLine)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 20)

                Spacer()

                Button(action: onDone) {
                    Text("Done")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.white)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .opacity(animateIn ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                animateIn = true
            }
        }
    }

    private var savedLine: String {
        let photoWord = deletedCount == 1 ? "photo" : "photos"
        return "\(deletedCount) \(photoWord) freed\n\(formattedBytes) saved"
    }

    private var subLine: String {
        "Deleted items are in Recently Deleted\nand permanently removed in 30 days."
    }

    private var formattedBytes: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        formatter.includesUnit = true
        return "~" + formatter.string(fromByteCount: approxBytesFreed)
    }
}
