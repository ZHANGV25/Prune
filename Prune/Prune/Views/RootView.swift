import SwiftUI
import Photos

struct RootView: View {
    @State private var hasOnboarded: Bool = RootView.initialOnboardingState()
    @State private var forcePaywall: Bool = RootView.shouldForcePaywall()
    @State private var forceOnboardingPage: Int? = RootView.forcedOnboardingPage()
    @State private var forceCelebration: Bool = RootView.shouldForceCelebration()
    @State private var forceDeck: Bool = RootView.shouldForceDeck()

    private static let args = ProcessInfo.processInfo.arguments

    private static func initialOnboardingState() -> Bool {
        if args.contains("-UITEST_SKIP_ONBOARDING") || args.contains("-UITEST_SHOW_CELEBRATION") || args.contains("-UITEST_OPEN_DECK") {
            return true
        }
        if args.contains("-UITEST_RESET_ONBOARDING") {
            UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
            return false
        }
        if args.contains("-UITEST_ONBOARD_P1") || args.contains("-UITEST_ONBOARD_P2") {
            UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
            return false
        }
        return UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }

    private static func shouldForcePaywall() -> Bool {
        args.contains("-UITEST_OPEN_PAYWALL")
    }

    private static func shouldForceCelebration() -> Bool {
        args.contains("-UITEST_SHOW_CELEBRATION")
    }

    private static func shouldForceDeck() -> Bool {
        args.contains("-UITEST_OPEN_DECK")
    }

    private static func forcedOnboardingPage() -> Int? {
        if args.contains("-UITEST_ONBOARD_P2") { return 1 }
        if args.contains("-UITEST_ONBOARD_P1") { return 0 }
        return nil
    }

    var body: some View {
        ZStack {
            if forceCelebration {
                CelebrationView(
                    deletedCount: 47,
                    approxBytesFreed: 47 * 3 * 1_048_576,  // ~141 MB
                    onDone: { forceCelebration = false }
                )
            } else if forceDeck {
                NavigationStack {
                    SwipeDeckView(feedType: .recents)
                }
            } else if hasOnboarded {
                HomeView()
                    .transition(.opacity)
                    .sheet(isPresented: $forcePaywall) { PaywallView() }
            } else {
                OnboardingView(forcedPage: forceOnboardingPage) {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        hasOnboarded = true
                    }
                }
                .transition(.opacity)
            }
        }
    }
}
