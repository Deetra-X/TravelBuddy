import SwiftUI

struct WelcomeScreen: View {
    var onTemporaryGoHome: () -> Void = {}

    var body: some View {
        ZStack {
            Color.travelBackground.ignoresSafeArea()

            VStack(spacing: 28) {
                HStack {
                    Spacer()

                    Button("Temporary: Go Home") {
                        onTemporaryGoHome()
                    }
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .frame(height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.travelPrimary)
                    )
                }

                Spacer()

                OnboardingIllustrationView(style: .welcome)
                    .frame(height: 180)

                Text("Near Me")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.travelTitle)

                Spacer()
            }
            .padding(.horizontal, 24)
        }
    }
}
