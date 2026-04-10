import SwiftUI

private enum AppRoute {
    case onboarding
    case auth
    case home
}

struct RootView: View {
    @StateObject private var sessionManager = SessionManager()
    @State private var route: AppRoute = .onboarding
    @State private var isInitializing = true

    var body: some View {
        Group {
            if isInitializing {
                // Show loading screen while checking session
                ZStack {
                    Color.travelBackground.ignoresSafeArea()
                    ProgressView()
                        .tint(Color.travelPrimary)
                }
                .onAppear {
                    Task {
                        // Give SessionManager time to load session from Keychain
                        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                        
                        await MainActor.run {
                            if sessionManager.isAuthenticated {
                                route = .home
                            } else {
                                route = .onboarding
                            }
                            isInitializing = false
                        }
                    }
                }
            } else {
                switch route {
                case .onboarding:
                    OnboardingFlowView(
                        onCompleted: {
                            route = .auth
                        },
                        onTemporaryHome: {
                            route = .home
                        }
                    )
                case .auth:
                    AuthFlowView {
                        route = .home
                    }
                case .home:
                    HomeScreen {
                        Task {
                            try await sessionManager.clearSession()
                            route = .auth
                        }
                    }
                }
            }
        }
        .environmentObject(sessionManager)
    }
}
