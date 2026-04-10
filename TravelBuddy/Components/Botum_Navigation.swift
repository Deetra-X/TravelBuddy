import SwiftUI

enum HomeTab: String, CaseIterable {
    case home = "Home"
    case myTrip = "My Trip"
    case wishlist = "Wishlist"
    case location = "Map"
    case profile = "Profile"

    var icon: String {
        switch self {
        case .home: return "house.fill"
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

    var body: some View {
        HStack {
            ForEach(HomeTab.allCases, id: \.self) { tab in
                Button {
                    onSelect(tab)
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: tab.icon)
                            .font(.headline)

                        Text(tab.rawValue)
                            .font(.caption2)
                    }
                    .foregroundStyle(tab == selectedTab ? Color.travelPrimary : Color.gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        Group {
                            if tab == selectedTab {
                                Capsule(style: .continuous)
                                    .fill(Color.travelPrimary.opacity(0.15))
                            }
                        }
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.85))
        )
    }
}
