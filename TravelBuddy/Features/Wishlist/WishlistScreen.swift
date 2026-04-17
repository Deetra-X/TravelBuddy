import SwiftUI
import Combine

struct WishlistScreen: View {
    @EnvironmentObject private var sessionManager: SessionManager
    @StateObject private var viewModel = WishlistViewModel()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                header

                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.top, 52)
                } else if viewModel.items.isEmpty {
                    emptyState
                        .frame(maxWidth: .infinity)
                        .padding(.top, 64)
                } else {
                    VStack(spacing: 14) {
                        ForEach(viewModel.items) { item in
                            WishlistRow(item: item) {
                                Task {
                                    await viewModel.remove(item: item, session: sessionManager.currentSession)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .background(Color.travelBackground.ignoresSafeArea())
        .task {
            await viewModel.load(session: sessionManager.currentSession)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Wishlist")
                .font(.largeTitle.bold())
                .foregroundStyle(Color.travelTitle)

            Text(viewModel.items.isEmpty ? "Start saving places you want to visit." : "Your saved places")
                .font(.subheadline)
                .foregroundStyle(Color.travelBody)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .stroke(Color.travelPrimary.opacity(0.12), lineWidth: 2)
                    .frame(width: 106, height: 106)

                Image(systemName: "heart")
                    .font(.system(size: 34, weight: .regular))
                    .foregroundStyle(.black)
            }

            VStack(spacing: 8) {
                Text("Empty")
                    .font(.title2.weight(.medium))
                    .foregroundStyle(Color.travelTitle)

                Text("Start building your travel wishlist by saving inspiring destinations and experiences.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.travelBody)
                    .padding(.horizontal, 18)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct WishlistRow: View {
    let item: WishlistPlaceItem
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: item.accentHex).opacity(0.95), Color.travelPrimary.opacity(0.55)],
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

                Image(systemName: "photo")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(8)
            }
            .frame(width: 92, height: 74)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.headline.weight(.medium))
                    .foregroundStyle(Color.travelTitle)
                    .lineLimit(1)

                Text(item.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color.travelBody)
                    .lineLimit(1)
            }

            Spacer()

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.title3)
                    .foregroundStyle(Color.red.opacity(0.9))
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.9))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }
}

@MainActor
private final class WishlistViewModel: ObservableObject {
    @Published private(set) var items: [WishlistPlaceItem] = []
    @Published private(set) var isLoading: Bool = false

    private let service: PlaceDetailsServiceProtocol

    init(service: PlaceDetailsServiceProtocol? = nil) {
        self.service = service ?? PlaceDetailsService()
    }

    func load(session: AuthSession?) async {
        guard let session else {
            items = []
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            items = try await service.fetchWishlist(userId: session.userId, accessToken: session.accessToken)
        } catch {
            items = []
        }
    }

    func remove(item: WishlistPlaceItem, session: AuthSession?) async {
        guard let session else { return }

        do {
            try await service.removeFromWishlist(userId: session.userId, placeId: item.placeId, accessToken: session.accessToken)
            items.removeAll { $0.id == item.id }
        } catch {
            return
        }
    }
}
