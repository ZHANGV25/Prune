import SwiftUI

struct RootView: View {
    @State private var hasOnboarded: Bool = RootView.initialOnboardingState()
    @State private var forcePaywall: Bool = RootView.shouldForcePaywall()
    @State private var forceOnboardingPage: Int? = RootView.forcedOnboardingPage()

    private static func initialOnboardingState() -> Bool {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-UITEST_SKIP_ONBOARDING") { return true }
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
        ProcessInfo.processInfo.arguments.contains("-UITEST_OPEN_PAYWALL")
    }

    private static func forcedOnboardingPage() -> Int? {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-UITEST_ONBOARD_P2") { return 1 }
        if args.contains("-UITEST_ONBOARD_P1") { return 0 }
        return nil
    }

    var body: some View {
        ZStack {
            if hasOnboarded {
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
