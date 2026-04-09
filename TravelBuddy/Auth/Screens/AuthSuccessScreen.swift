import SwiftUI

struct AuthSuccessScreen: View {
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            Color.travelBackground.ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                Circle()
                    .stroke(Color.travelPrimary, lineWidth: 4)
                    .frame(width: 124, height: 124)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.title)
                            .foregroundStyle(Color.travelPrimary)
                    )

                Text("Success!")
                    .font(.title.bold())
                    .foregroundStyle(Color.travelTitle)

                Text("Congratulations! You have been successfully authenticated")
                    .font(.body)
                    .foregroundStyle(Color.travelBody)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 26)

                Spacer()

                AuthPrimaryButton(title: "Continue", isLoading: false, action: onContinue)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
            }
        }
    }
}
