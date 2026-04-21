import SwiftUI

struct RootView: View {
    @State private var hasOnboarded: Bool = RootView.initialOnboardingState()

    private static func initialOnboardingState() -> Bool {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-UITEST_SKIP_ONBOARDING") { return true }
        if args.contains("-UITEST_RESET_ONBOARDING") {
            UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
            return false
        }
        return UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }

    var body: some View {
        ZStack {
            if hasOnboarded {
                HomeView()
                    .transition(.opacity)
            } else {
                OnboardingView {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        hasOnboarded = true
                    }
                }
                .transition(.opacity)
            }
        }
    }
}
