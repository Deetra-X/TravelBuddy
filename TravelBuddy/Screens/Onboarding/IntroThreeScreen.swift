import SwiftUI

struct IntroThreeScreen: View {
    let onPrevious: () -> Void
    let onFinish: () -> Void

    var body: some View {
        onboardingLayout(
            illustration: .introThree,
            title: "Enjoy Your Trip",
            subtitle: "Embrace the joy of travel! Explore new horizons, savor every moment, and create lasting memories. Your journey begins here. Enjoy the trip!",
            page: 2,
            leadingTitle: "Previous",
            trailingTitle: "Finish",
            leadingAction: onPrevious,
            trailingAction: onFinish,
            showsTrailingChevron: true
        )
    }

    @ViewBuilder
    private func onboardingLayout(
        illustration: OnboardingIllustrationStyle,
        title: String,
        subtitle: String,
        page: Int,
        leadingTitle: String,
        trailingTitle: String,
        leadingAction: @escaping () -> Void,
        trailingAction: @escaping () -> Void,
        showsTrailingChevron: Bool
    ) -> some View {
        ZStack {
            Color.travelBackground.ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer().frame(height: 36)

                OnboardingIllustrationView(style: illustration)
                    .frame(height: 240)

                PageDots(activeIndex: page, count: 3)

                VStack(spacing: 14) {
                    Text(title)
                        .font(.system(size: 25, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.travelTitle)

                    Text(subtitle)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.travelBody)
                        .padding(.horizontal, 18)
                        .lineSpacing(2)
                }

                Spacer()

                OnboardingActionNavigation(
                    leadingTitle: leadingTitle,
                    trailingTitle: trailingTitle,
                    leadingAction: leadingAction,
                    trailingAction: trailingAction,
                    showsTrailingChevron: showsTrailingChevron
                )
            }
            .padding(.bottom, 8)
        }
    }
}
