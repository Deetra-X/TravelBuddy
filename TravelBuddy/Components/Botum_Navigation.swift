import SwiftUI

enum HomeTab: String, CaseIterable {
    case home = "Home"
    case journey = "Journey"
    case myTrip = "My Trip"
    case wishlist = "Wishlist"
    case location = "Map"
    case profile = "Profile"

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .journey: return "map.circle.fill"
        case .myTrip: return "calendar.badge.plus"
        case .wishlist: return "heart.fill"
        case .location: return "location"
        case .profile: return "person"
        }
    }
}

struct Botum_Navigation: View {
    let selectedTab: HomeTab
    var onSelect: (HomeTab) -> Void

    private var bottomTabs: [HomeTab] {
        HomeTab.allCases.filter { $0 != .profile }
    }

    var body: some View {
        HStack(spacing: 8) {
            ForEach(bottomTabs, id: \.self) { tab in
                Button {
                    onSelect(tab)
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: tab.icon)
                            .font(.headline)

                        Text(tab.rawValue)
                            .font(.caption2)
                    }
                    .foregroundStyle(tab == selectedTab ? Color.travelPrimary : Color.travelBody.opacity(0.82))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(
                        Group {
                            if tab == selectedTab {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .stroke(Color.white.opacity(0.55), lineWidth: 0.8)
                                    )
                            }
                        }
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.45), lineWidth: 0.9)
                )
                .shadow(color: .black.opacity(0.13), radius: 20, x: 0, y: 8)
        )
    }
}
