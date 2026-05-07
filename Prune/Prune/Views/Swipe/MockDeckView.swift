import SwiftUI

// Marketing-screenshot mock for the App Store 6.9" "swipe deck" slot.
// Bypasses PHPhotoLibrary entirely so we can render the deck on a simulator
// with no permission dialog and no real photos. Active only when launched
// with -UITEST_SCREENSHOT_DECK.
struct MockDeckView: View {
    @Environment(\.dismiss) var dismissAction

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            GeometryReader { geo in
                MockPhotoCard(scene: .sunsetMountain)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .overlay(alignment: .bottomLeading) {
                        Text("KEEP")
                            .font(.largeTitle).fontWeight(.heavy)
                            .foregroundColor(.green)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 10).stroke(Color.green, lineWidth: 4))
                            .rotationEffect(.degrees(-15))
                            .padding(.bottom, 150).padding(.leading, 40)
                    }
                    .offset(x: 60)
                    .rotationEffect(.degrees(3))
            }

            VStack {
                HStack {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                        .shadow(radius: 4)
                        .padding(8)

                    Spacer()

                    Text("128 left")
                        .font(.headline)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                        .foregroundColor(.white)

                    Spacer()

                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.white.opacity(0.8))
                        .shadow(radius: 4)
                        .padding(8)
                }
                .padding()

                Spacer()

                HStack(spacing: 40) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.left")
                        Text("DELETE")
                    }
                    .font(.caption).fontWeight(.bold)
                    .foregroundColor(.red.opacity(0.8))

                    Text("|").foregroundColor(.white.opacity(0.3))

                    HStack(spacing: 4) {
                        Text("KEEP")
                        Image(systemName: "arrow.right")
                    }
                    .font(.caption).fontWeight(.bold)
                    .foregroundColor(.green.opacity(0.8))
                }
                .padding(.bottom, 30)
            }
        }
    }
}

private enum MockScene {
    case sunsetMountain

    var topColor: Color {
        switch self {
        case .sunsetMountain: return Color(red: 0.95, green: 0.55, blue: 0.25)
        }
    }

    var bottomColor: Color {
        switch self {
        case .sunsetMountain: return Color(red: 0.30, green: 0.20, blue: 0.45)
        }
    }

    var symbol: String {
        switch self {
        case .sunsetMountain: return "mountain.2.fill"
        }
    }

    var symbolColor: Color {
        switch self {
        case .sunsetMountain: return Color(red: 0.10, green: 0.10, blue: 0.20)
        }
    }
}

private struct MockPhotoCard: View {
    let scene: MockScene

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(
                    colors: [scene.topColor, scene.bottomColor],
                    startPoint: .top,
                    endPoint: .bottom
                )
                Circle()
                    .fill(Color.yellow.opacity(0.95))
                    .frame(width: 110, height: 110)
                    .blur(radius: 4)
                    .offset(x: 0, y: -geo.size.height * 0.15)
                Image(systemName: scene.symbol)
                    .font(.system(size: 240, weight: .black))
                    .foregroundStyle(scene.symbolColor)
                    .offset(y: geo.size.height * 0.18)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
            .cornerRadius(20)
        }
        .padding(12)
        .shadow(radius: 10)
    }
}
