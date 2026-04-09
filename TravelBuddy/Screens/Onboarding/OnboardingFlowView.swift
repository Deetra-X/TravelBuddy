import SwiftUI

struct OnboardingFlowView: View {
    @State private var page: OnboardingPage = .welcome

    var body: some View {
        Group {
            switch page {
            case .welcome:
                WelcomeScreen()
            case .introOne:
                IntroOneScreen(
                    onSkip: { page = .introThree },
                    onNext: { page = .introTwo }
                )
            case .introTwo:
                IntroTwoScreen(
                    onPrevious: { page = .introOne },
                    onNext: { page = .introThree }
                )
            case .introThree:
                IntroThreeScreen(
                    onPrevious: { page = .introTwo },
                    onFinish: { page = .welcome }
                )
            }
        }
        .onAppear {
            if page == .welcome {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
                    if page == .welcome {
                        page = .introOne
                    }
                }
            }
        }
    }
}
