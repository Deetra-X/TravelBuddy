import SwiftUI

struct OnboardingFlowView: View {
    let onCompleted: () -> Void
    @State private var page: OnboardingPage = .welcome

    var body: some View {
        Group {
            switch page {
            case .welcome:
                WelcomeScreen(
                    onTour: {
                        page = .introOne
                    }
                )
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
                    onFinish: {
                        page = .welcome
                        onCompleted()
                    }
                )
            }
        }
    }
}
