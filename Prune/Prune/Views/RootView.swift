import SwiftUI

struct RootView: View {
    @State private var hasOnboarded: Bool = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")

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
