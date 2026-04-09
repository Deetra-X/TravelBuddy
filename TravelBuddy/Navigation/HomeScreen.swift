import SwiftUI
import MapKit
import CoreLocation

struct HomeScreen: View {
    var onLogout: () -> Void

    @StateObject private var locationManager = UserLocationManager()
    @State private var selectedTab: HomeTab = .home
    @State private var contentTab: HomeTab = .home
    @State private var isMenuOpen = false
    @State private var wishlistItems: [WishlistPlaceItem] = []

    var body: some View {
        ZStack {
            Color.travelBackground.ignoresSafeArea()

            Group {
                if contentTab == .wishlist {
                    WishlistScreen(items: $wishlistItems)
                } else if contentTab == .location {
                    MapScreen(locationManager: locationManager) {
                        selectedTab = .home
                        contentTab = .home
                    }
                } else if contentTab == .profile {
                    ProfileScreen()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 18) {
                            topBar

                            homeBanner

                            HomeSectionHeader(title: "Explore Around you", trailingText: "View all")

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(sortedPlaces) { item in
                                        ExplorePlaceCard(item: item, distanceText: distanceText(for: item.coordinate))
                                    }
                                }
                            }

                            HomeSectionHeader(title: "Quick Plans")

                            VStack(spacing: 10) {
                                ForEach(HomeMockData.quickPlans) { item in
                                    QuickPlanCard(item: item)
                                }
                            }

                            HomeSectionHeader(title: "Experiences You’ll Love")

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                ForEach(HomeMockData.experiences) { item in
                                    ExperienceCard(item: item)
                                }
                            }

                            HomeSectionHeader(title: "Nearby map")
                            NearbyMapCard(region: $locationManager.region, places: Array(sortedPlaces.prefix(3)))

                            HomeSectionHeader(title: "Ongoing trip", trailingText: "Active now")
                            OngoingTripCard(item: HomeMockData.ongoingTrip)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 110)
                    }
                }
            }

            if isMenuOpen {
                Color.black.opacity(0.18)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isMenuOpen = false
                        }
                    }
            }

            if isMenuOpen {
                HStack(spacing: 0) {
                    SideBarMenu(
                        onClose: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isMenuOpen = false
                            }
                        },
                        onLogout: onLogout
                    )

                    Spacer()
                }
                .transition(.move(edge: .leading))
                .zIndex(2)
            }
        }
        .onAppear {
            locationManager.requestAndStart()
        }
        .safeAreaInset(edge: .bottom) {
            Botum_Navigation(selectedTab: selectedTab) { tab in
                selectedTab = tab

                contentTab = tab
                if isMenuOpen {
                    isMenuOpen = false
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 8)
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isMenuOpen = true
                }
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.headline)
                    .foregroundStyle(Color.travelTitle)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(.white.opacity(0.85)))
            }
            .buttonStyle(.plain)

            Spacer()

            Text("9:41")
                .font(.subheadline.weight(.semibold))
                .opacity(0)

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isMenuOpen = true
                }
            } label: {
                Image(systemName: "person.fill")
                    .font(.subheadline)
                    .foregroundStyle(Color.travelTitle)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(.white.opacity(0.85)))
            }
            .buttonStyle(.plain)
        }
    }

    private var homeBanner: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color.travelPrimary.opacity(0.95), Color.green.opacity(0.7)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 130)
            .overlay(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("• Today in Ella")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))

                    Text("Sunny in Ella ☀️")
                        .font(.headline)
                        .foregroundStyle(.white)

                    Text("Perfect for hiking")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                }
                .padding(14)
            }
    }

    private var sortedPlaces: [PlaceCardItem] {
        guard let currentLocation = locationManager.location else {
            return HomeMockData.explorePlaces
        }

        return HomeMockData.explorePlaces.sorted { left, right in
            let leftDistance = currentLocation.distance(from: CLLocation(latitude: left.coordinate.latitude, longitude: left.coordinate.longitude))
            let rightDistance = currentLocation.distance(from: CLLocation(latitude: right.coordinate.latitude, longitude: right.coordinate.longitude))
            return leftDistance < rightDistance
        }
    }

    private func distanceText(for coordinate: CLLocationCoordinate2D) -> String {
        guard let currentLocation = locationManager.location else {
            return "-- km"
        }

        let placeLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let distanceInKm = currentLocation.distance(from: placeLocation) / 1000
        return String(format: "%.1f km away", distanceInKm)
    }
}
