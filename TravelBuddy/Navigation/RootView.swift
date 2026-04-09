import SwiftUI

private enum AppRoute {
    case onboarding
    case auth
    case home
}

struct RootView: View {
    @State private var route: AppRoute = .onboarding

    var body: some View {
        Group {
            switch route {
            case .onboarding:
                OnboardingFlowView {
                    route = .auth
                }
            case .auth:
                AuthFlowView {
                    route = .home
                }
            case .home:
                HomeScreen {
                    route = .auth
                }
            }
        }
    }
}
