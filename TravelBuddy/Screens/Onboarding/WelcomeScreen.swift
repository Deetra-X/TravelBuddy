import SwiftUI

struct WelcomeScreen: View {
    var body: some View {
        ZStack {
            Color.travelBackground.ignoresSafeArea()

            VStack(spacing: 28) {
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
