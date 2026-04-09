import SwiftUI

struct IntroTwoScreen: View {
    let onPrevious: () -> Void
    let onNext: () -> Void

    var body: some View {
        onboardingLayout(
            illustration: .introTwo,
            title: "Select Your Resting place",
            subtitle: "Indulge in tranquility and comfort. Choose your perfect resting place with us, where serenity meets luxury. Select a haven that resonates with your soul. Your ultimate relaxation awaits.",
            page: 1,
            leadingTitle: "Previous",
            trailingTitle: "Next",
            leadingAction: onPrevious,
            trailingAction: onNext
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
        trailingAction: @escaping () -> Void
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
                    showsTrailingChevron: true
                )
            }
            .padding(.bottom, 8)
        }
    }
}
