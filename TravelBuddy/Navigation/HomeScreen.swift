import SwiftUI

struct HomeScreen: View {
    var onLogout: () -> Void

    var body: some View {
        ZStack {
            Color.travelBackground.ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "location.circle.fill")
                    .font(.system(size: 86))
                    .foregroundStyle(Color.travelPrimary)

                Text("Home Screen")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.travelTitle)

                Text("User is logged in successfully.")
                    .font(.system(size: 18, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.travelBody)

                Button("Log out") {
                    onLogout()
                }
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.travelPrimary)
                )
                .padding(.horizontal, 24)
            }
        }
    }
}
