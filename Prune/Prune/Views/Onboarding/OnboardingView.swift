import SwiftUI
import AppTrackingTransparency
import AdSupport

struct OnboardingView: View {
    let onComplete: () -> Void

    @State private var page: Int = 0
    @State private var isRequestingPhoto = false
    @ObservedObject private var photoService = PhotoLibraryService.shared

    private let totalPages = 3

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress dots
                HStack(spacing: 8) {
                    ForEach(0..<totalPages, id: \.self) { i in
                        Capsule()
                            .fill(i == page ? Color.white : Color.white.opacity(0.25))
                            .frame(width: i == page ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: page)
                    }
                }
                .padding(.top, 60)

                Spacer()

                Group {
                    switch page {
                    case 0: hookPage
                    case 1: privacyPage
                    default: permissionsPage
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

                Spacer()

                bottomButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Pages

    private var hookPage: some View {
        VStack(spacing: 24) {
            Image(systemName: "photo.stack.fill")
                .font(.system(size: 80))
                .foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))

            Text("Clean your\nphoto library\nin minutes")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Text("Swipe right to keep, left to delete.\nJust like dating apps — but for your camera roll.")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.horizontal, 24)
    }

    private var privacyPage: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 80))
                .foregroundStyle(LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing))

            Text("Your photos\nstay on device")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            VStack(alignment: .leading, spacing: 16) {
                privacyBullet("checkmark.circle.fill", "No uploads, no cloud processing")
                privacyBullet("checkmark.circle.fill", "Uses Apple's Photos framework")
                privacyBullet("checkmark.circle.fill", "Delete sends to Recently Deleted")
            }
            .padding(.horizontal, 32)
            .padding(.top, 8)
        }
        .padding(.horizontal, 24)
    }

    private var permissionsPage: some View {
        VStack(spacing: 24) {
            Image(systemName: "hand.wave.fill")
                .font(.system(size: 80))
                .foregroundStyle(LinearGradient(colors: [.orange, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))

            Text("Almost ready")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.white)

            Text("Next, iOS will ask for access to your photos so Prune can show and delete them. Choose Allow Full Access.")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.horizontal, 24)
    }

    private func privacyBullet(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.green)
                .font(.title3)
            Text(text)
                .foregroundColor(.white)
                .font(.body)
            Spacer()
        }
    }

    // MARK: - Bottom action

    private var bottomButton: some View {
        Button(action: handleBottomTap) {
            HStack {
                if isRequestingPhoto {
                    ProgressView().tint(.black)
                } else {
                    Text(buttonTitle)
                        .font(.headline)
                }
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Color.white)
            .clipShape(Capsule())
        }
        .disabled(isRequestingPhoto)
    }

    private var buttonTitle: String {
        switch page {
        case 0, 1: return "Continue"
        default: return "Allow Access"
        }
    }

    private func handleBottomTap() {
        if page < totalPages - 1 {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                page += 1
            }
        } else {
            requestPermissionsThenFinish()
        }
    }

    private func requestPermissionsThenFinish() {
        isRequestingPhoto = true
        Task {
            _ = await photoService.requestAuthorization()
            if #available(iOS 14, *) {
                _ = await ATTrackingManager.requestTrackingAuthorization()
            }
            isRequestingPhoto = false
            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
            onComplete()
        }
    }
}

@available(iOS 14, *)
extension ATTrackingManager {
    static func requestTrackingAuthorization() async -> ATTrackingManager.AuthorizationStatus {
        await withCheckedContinuation { continuation in
            ATTrackingManager.requestTrackingAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }
}
