import SwiftUI
import UIKit

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
        Image("main_image")
            .resizable()
            .scaledToFit()
            .frame(width: 180, height: 180)
    }

    private var introOneIllustration: some View {
        Group {
            if let image = loadBundledImage(
                candidates: [
                    ("Group 302", "png", nil),
                    ("Group 302.png", nil, nil),
                    ("Group 302", "png", "Icons"),
                    ("Group 302.png", nil, "Icons")
                ]
            ) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Image("Group 302")
                    .resizable()
                    .scaledToFit()
            }
        }
        .frame(width: 250, height: 220)
    }

    private var introTwoIllustration: some View {
        Group {
            if let image = loadBundledImage(
                candidates: [
                    ("bro", "png", nil),
                    ("bro.png", nil, nil),
                    ("bro", "png", "Icons"),
                    ("bro.png", nil, "Icons")
                ]
            ) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Image("bro")
                    .resizable()
                    .scaledToFit()
            }
        }
        .frame(width: 250, height: 220)
    }

    private var introThreeIllustration: some View {
        Group {
            if let image = loadBundledImage(
                candidates: [
                    ("rafiki", "png", nil),
                    ("rafiki.png", nil, nil),
                    ("rafiki", "png", "Icons"),
                    ("rafiki.png", nil, "Icons")
                ]
            ) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Image("rafiki")
                    .resizable()
                    .scaledToFit()
            }
        }
        .frame(width: 250, height: 220)
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

    private func loadBundledImage(candidates: [(name: String, ext: String?, directory: String?)]) -> UIImage? {
        for candidate in candidates {
            if let path = Bundle.main.path(forResource: candidate.name, ofType: candidate.ext, inDirectory: candidate.directory),
               let image = UIImage(contentsOfFile: path) {
                return image
            }
        }
        return nil
    }
}
