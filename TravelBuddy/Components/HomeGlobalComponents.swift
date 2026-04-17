import SwiftUI
import Combine

@MainActor
private final class DestinationWishlistButtonViewModel: ObservableObject {
    @Published private(set) var isWishlisted: Bool = false
    @Published private(set) var isLoading: Bool = false

    private let service: PlaceDetailsServiceProtocol
    private let directPlaceId: String?
    private let source: WishlistPlaceSource
    private let placeName: String
    private let district: String
    private let imageURLString: String?
    private var resolvedPlaceId: String?

    init(
        directPlaceId: String? = nil,
        source: WishlistPlaceSource = .manualPlannerPlaces,
        placeName: String,
        district: String,
        imageURL: URL? = nil,
        service: PlaceDetailsServiceProtocol = PlaceDetailsService()
    ) {
        self.directPlaceId = directPlaceId
        self.source = source
        self.placeName = placeName
        self.district = district
        self.imageURLString = imageURL?.absoluteString
        self.service = service
    }

    func load(session: AuthSession?) async {
        guard let session else {
            isWishlisted = false
            return
        }

        guard let placeId = await resolvePlaceId() else {
            isWishlisted = false
            return
        }

        do {
            isWishlisted = try await service.isWishlisted(userId: session.userId, placeId: placeId, source: source, accessToken: session.accessToken)
        } catch {
            isWishlisted = false
        }
    }

    func toggle(session: AuthSession?) async {
        guard let session else {
            return
        }

        guard let placeId = await resolvePlaceId() else {
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            if isWishlisted {
                try await service.removeFromWishlist(userId: session.userId, placeId: placeId, source: source, accessToken: session.accessToken)
                isWishlisted = false
            } else {
                try await service.addToWishlist(
                    userId: session.userId,
                    placeId: placeId,
                    source: source,
                    placeName: placeName,
                    district: district,
                    imageURLString: imageURLString,
                    accessToken: session.accessToken
                )
                isWishlisted = true
            }
        } catch {
            return
        }
    }

    private func resolvePlaceId() async -> String? {
        if let resolvedPlaceId {
            return resolvedPlaceId
        }

        if let directPlaceId {
            resolvedPlaceId = directPlaceId
            return directPlaceId
        }

        do {
            let place = try await service.fetchPlaceId(name: placeName, district: district, source: source)
            resolvedPlaceId = place
            return resolvedPlaceId
        } catch {
            return nil
        }
    }
}

struct DestinationWishlistButton: View {
    @EnvironmentObject private var sessionManager: SessionManager
    @StateObject private var viewModel: DestinationWishlistButtonViewModel

    init(directPlaceId: String? = nil, source: WishlistPlaceSource = .manualPlannerPlaces, placeName: String, district: String, imageURL: URL? = nil) {
        _viewModel = StateObject(
            wrappedValue: DestinationWishlistButtonViewModel(
                directPlaceId: directPlaceId,
                source: source,
                placeName: placeName,
                district: district,
                imageURL: imageURL
            )
        )
    }

    var body: some View {
        Button {
            Task {
                await viewModel.toggle(session: sessionManager.currentSession)
            }
        } label: {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.92))

                if viewModel.isLoading {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: viewModel.isWishlisted ? "heart.fill" : "heart")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(viewModel.isWishlisted ? Color.red : Color.travelBody)
                }
            }
            .frame(width: 30, height: 30)
            .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .task(id: sessionManager.currentSession?.userId) {
            await viewModel.load(session: sessionManager.currentSession)
        }
    }
}

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
            .overlay(alignment: .topLeading) {
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
            .overlay(alignment: .topTrailing) {
                DestinationWishlistButton(
                    directPlaceId: item.wishlistPlaceId,
                    source: item.wishlistSource,
                    placeName: item.name,
                    district: item.subtitle,
                    imageURL: item.imageURL
                )
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

    private var localImage: Image? {
        guard let imageName = item.imageName else {
            return nil
        }

        if let image = UIImage(named: imageName)
            ?? UIImage(named: "\(imageName).jpg")
            ?? UIImage(named: "\(imageName).JPG") {
            return Image(uiImage: image)
        }

        return nil
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(hex: item.accentHex).opacity(0.4))

            if let localImage {
                localImage
                    .resizable()
                    .scaledToFill()
            } else if let imageURL = item.imageURL {
                AsyncImage(url: imageURL) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFill()
                    }
                }
            }

            LinearGradient(
                colors: [.black.opacity(0.45), .black.opacity(0.2), .clear],
                startPoint: .bottom,
                endPoint: .top
            )

            VStack(alignment: .leading, spacing: 5) {
                Image(systemName: item.icon)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.95))

                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)

                Text(item.subtitle)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.88))
            }
            .padding(10)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        }
        .frame(height: 118)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
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
