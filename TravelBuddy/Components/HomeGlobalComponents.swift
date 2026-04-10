import SwiftUI

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        let red = Double((value >> 16) & 0xFF) / 255
        let green = Double((value >> 8) & 0xFF) / 255
        let blue = Double(value & 0xFF) / 255
        self.init(red: red, green: green, blue: blue)
    }
}

struct HomeSectionHeader: View {
    let title: String
    var trailingText: String? = nil
    var onTrailingTap: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.travelTitle)

            Spacer()

            if let trailingText {
                if let onTrailingTap {
                    Button(action: onTrailingTap) {
                        Text(trailingText)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.travelPrimary)
                    }
                    .buttonStyle(.plain)
                } else {
                    Text(trailingText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.travelPrimary)
                }
            }
        }
    }
}

struct ExplorePlaceCard: View {
    let item: PlaceCardItem
    let distanceText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: item.accentHex), Color.travelPrimary.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                if let imageURL = item.imageURL {
                    AsyncImage(url: imageURL) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .scaledToFill()
                        } else {
                            Color.clear
                        }
                    }
                }

                LinearGradient(
                    colors: [.black.opacity(0.24), .clear, .black.opacity(0.18)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .frame(width: 156, height: 146)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(alignment: .topTrailing) {
                HStack(spacing: 3) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                    Text(String(format: "%.1f", item.rating))
                        .font(.caption2.weight(.semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(.black.opacity(0.28), in: Capsule())
                .padding(8)
            }
            .overlay(alignment: .bottomLeading) {
                Image(systemName: "mountain.2.fill")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.95))
                    .padding(10)
            }

            Text(item.name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.travelTitle)
                .lineLimit(1)

            Text(distanceText)
                .font(.caption)
                .foregroundStyle(Color.travelBody)

            Text(item.description)
                .font(.caption2)
                .foregroundStyle(Color.travelBody)
                .lineLimit(2)
                .frame(height: 30, alignment: .top)
        }
        .padding(10)
        .frame(width: 176, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.75))
        )
    }
}

struct QuickPlanCard: View {
    let item: QuickPlanItem

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.travelPrimary.opacity(0.16))
                .frame(width: 38, height: 38)
                .overlay {
                    Image(systemName: item.icon)
                        .foregroundStyle(Color.travelPrimary)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.travelTitle)

                Text(item.subtitle)
                    .font(.caption)
                    .foregroundStyle(Color.travelBody)
            }

            Spacer()

            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.travelPrimary.opacity(0.16))
                .frame(width: 38, height: 38)
                .overlay {
                    Image(systemName: "arrow.clockwise")
                        .foregroundStyle(Color.travelTitle)
                }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.72))
        )
    }
}

struct ExperienceCard: View {
    let item: ExperienceItem

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: item.accentHex), Color.travelPrimary.opacity(0.55)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            VStack(alignment: .leading, spacing: 5) {
                Image(systemName: item.icon)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.9))

                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)

                Text(item.subtitle)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(10)
        }
        .frame(height: 118)
    }
}

struct OngoingTripCard: View {
    let item: OngoingTripItem

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.travelPrimary.opacity(0.28))
                .frame(width: 46, height: 46)
                .overlay {
                    Image(systemName: "mountain.2.fill")
                        .foregroundStyle(Color.travelPrimary)
                }

            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.travelTitle)

                Text(item.progressText)
                    .font(.caption)
                    .foregroundStyle(Color.travelBody)

                ProgressView(value: item.progress)
                    .progressViewStyle(.linear)
                    .tint(Color.travelPrimary)
            }

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.78))
        )
    }
}
