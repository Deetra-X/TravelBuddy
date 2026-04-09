import SwiftUI

enum OnboardingIllustrationStyle {
    case welcome
    case introOne
    case introTwo
    case introThree
}

struct OnboardingIllustrationView: View {
    let style: OnboardingIllustrationStyle

    var body: some View {
        ZStack {
            switch style {
            case .welcome:
                welcomeIllustration
            case .introOne:
                introOneIllustration
            case .introTwo:
                introTwoIllustration
            case .introThree:
                introThreeIllustration
            }
        }
    }

    private var welcomeIllustration: some View {
        ZStack {
            Circle()
                .fill(Color.travelPrimary.opacity(0.15))
                .frame(width: 116, height: 116)

            Circle()
                .fill(Color.travelSoftTeal.opacity(0.9))
                .frame(width: 68, height: 68)

            Image(systemName: "location.fill")
                .font(.system(size: 62, weight: .light))
                .foregroundStyle(Color.travelPrimary)
                .offset(y: 2)

            Image(systemName: "globe.asia.australia.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.white)
                .offset(y: 2)

            Image(systemName: "airplane")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.travelPrimary)
                .rotationEffect(.degrees(18))
                .offset(x: 34, y: -30)
        }
    }

    private var introOneIllustration: some View {
        ZStack(alignment: .center) {
            Ellipse()
                .fill(Color.white.opacity(0.72))
                .frame(width: 240, height: 112)
                .offset(y: 62)

            Circle()
                .fill(Color.travelSoftTeal.opacity(0.65))
                .frame(width: 120, height: 120)
                .offset(x: -66, y: -34)

            Circle()
                .fill(Color.travelSoftTeal.opacity(0.45))
                .frame(width: 92, height: 92)
                .offset(x: 54, y: -42)

            HStack(alignment: .bottom, spacing: 26) {
                travelerIllustration(tint: .travelPrimary, suitcaseTint: .travelPrimary.opacity(0.78))
                travelerIllustration(tint: Color(red: 0.98, green: 0.47, blue: 0.47), suitcaseTint: Color(red: 0.34, green: 0.56, blue: 0.88))
            }
            .offset(y: 18)

            Image(systemName: "airplane")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color.travelPrimary.opacity(0.8))
                .rotationEffect(.degrees(-18))
                .offset(x: -6, y: -42)
        }
    }

    private var introTwoIllustration: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.travelPrimary.opacity(0.3), lineWidth: 2)
                .frame(width: 118, height: 160)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.white.opacity(0.78))
                        .frame(width: 118, height: 160)
                )
                .offset(x: 52, y: -2)

            VStack(spacing: 10) {
                Image(systemName: "map.fill")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(Color.travelPrimary)

                HStack(spacing: 12) {
                    pinDot(color: Color(red: 0.98, green: 0.47, blue: 0.47))
                    pinDot(color: Color(red: 0.34, green: 0.56, blue: 0.88))
                    pinDot(color: Color.travelPrimary)
                }
            }
            .offset(x: 42, y: -4)

            travelerIllustration(tint: Color(red: 0.20, green: 0.56, blue: 0.63), suitcaseTint: Color(red: 0.16, green: 0.19, blue: 0.23))
                .offset(x: -44, y: 20)
        }
    }

    private var introThreeIllustration: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.68))
                .frame(width: 130, height: 130)
                .offset(x: 72, y: -44)

            Image(systemName: "sun.max.fill")
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(Color(red: 0.97, green: 0.72, blue: 0.40).opacity(0.85))
                .offset(x: 84, y: -64)

            VStack(spacing: 10) {
                Image(systemName: "figure.arms.open")
                    .font(.system(size: 58, weight: .semibold))
                    .foregroundStyle(Color(red: 0.60, green: 0.76, blue: 0.85))

                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color(red: 0.25, green: 0.30, blue: 0.34))
                        .frame(width: 12, height: 32)
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color(red: 0.25, green: 0.30, blue: 0.34))
                        .frame(width: 12, height: 32)
                }
                .offset(y: -10)
            }
            .offset(x: -42, y: 14)

            VStack(spacing: 8) {
                Image(systemName: "suitcase.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Color.travelPrimary)
                    .offset(x: 32, y: 34)

                Image(systemName: "airplane")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.travelPrimary.opacity(0.7))
                    .rotationEffect(.degrees(18))
                    .offset(x: 68, y: -20)
            }
        }
    }

    private func travelerIllustration(tint: Color, suitcaseTint: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: "person.fill")
                .font(.system(size: 42, weight: .bold))
                .foregroundStyle(tint)

            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(suitcaseTint)
                .frame(width: 22, height: 16)
                .overlay(
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .stroke(Color.white.opacity(0.8), lineWidth: 1)
                        .frame(width: 12, height: 8)
                        .offset(y: -6)
                )
        }
    }

    private func pinDot(color: Color) -> some View {
        Circle()
            .fill(color)
            .frame(width: 10, height: 10)
    }
}
