import SwiftUI
import UIKit

struct WelcomeScreen: View {
    var onTour: () -> Void = {}

    var body: some View {
        ZStack {
            Color.travelBackground.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer(minLength: 12)

                welcomeImage
                    .frame(height: 210)

                Text("Near Me")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.travelTitle)

                Text("Explore destinations, plan trips, and check the weather before you go.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.travelBody)
                    .padding(.horizontal, 8)

                Spacer()

                Button {
                    onTour()
                } label: {
                    Text("Where to?")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.travelPrimary)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
    }

    private var welcomeImage: some View {
        Group {
            if let uiImage = loadWelcomeImage() {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .shadow(color: Color.travelPrimary.opacity(0.18), radius: 10, x: 0, y: 8)
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 56, weight: .semibold))
                    .foregroundStyle(Color.travelPrimary.opacity(0.45))
            }
        }
    }

    private func loadWelcomeImage() -> UIImage? {
        let candidates = [
            Bundle.main.path(forResource: "main_image", ofType: "png"),
            Bundle.main.path(forResource: "main_image", ofType: nil),
            Bundle.main.path(forResource: "main image", ofType: "png"),
            Bundle.main.path(forResource: "main image", ofType: nil)
        ]

        for path in candidates.compactMap({ $0 }) {
            if let image = UIImage(contentsOfFile: path) {
                return image
            }
        }

        return UIImage(named: "main_image")
    }
}
