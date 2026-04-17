import SwiftUI
import MapKit
import CoreLocation

struct HomeScreen: View {
    var onLogout: () -> Void

    @StateObject private var locationManager = UserLocationManager()
    @StateObject private var weatherViewModel = WeatherViewModel()
    @StateObject private var nearbyPlacesViewModel = NearbyPlacesViewModel()
    @State private var selectedTab: HomeTab = .home
    @State private var contentTab: HomeTab = .home
    @State private var isMenuOpen = false
    @State private var showAdvancedSettings = false
    @State private var showAllNearbyPlaces = false

    private let fallbackCoordinate = CLLocationCoordinate2D(latitude: 6.906555, longitude: 79.87071)

    var body: some View {
        ZStack {
            Color.travelBackground.ignoresSafeArea()

            Group {
                if contentTab == .myTrip {
                    ManualTripPlannerScreen()
                } else if contentTab == .wishlist {
                    WishlistScreen()
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

                            manualPlanShortcut

                            HomeSectionHeader(
                                title: "Explore Around you",
                                trailingText: "View all",
                                onTrailingTap: {
                                    showAllNearbyPlaces = true
                                }
                            )

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(nearbyPlacesToShow) { item in
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
                        onLogout: onLogout,
                        onAdvancedSettings: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isMenuOpen = false
                            }
                            showAdvancedSettings = true
                        }
                    )

                    Spacer()
                }
                .transition(.move(edge: .leading))
                .zIndex(2)
            }
        }
        .fullScreenCover(isPresented: $showAdvancedSettings) {
            AdvancedSettingsScreen {
                showAdvancedSettings = false
            }
        }
        .fullScreenCover(isPresented: $showAllNearbyPlaces) {
            NearbyPlacesListScreen(
                items: allNearbyPlaces,
                currentLocation: referenceLocation,
                onClose: {
                    showAllNearbyPlaces = false
                }
            )
        }
        .onAppear {
            locationManager.requestAndStart()
            weatherViewModel.refreshIfNeeded(from: locationManager.location)
            nearbyPlacesViewModel.loadPlacesIfNeeded(
                currentLocation: referenceLocation,
                districtFilter: shouldForceColomboOnly ? "Colombo" : nil
            )
        }
        .onReceive(locationManager.$location) { location in
            weatherViewModel.refreshIfNeeded(from: location)
            nearbyPlacesViewModel.updateNearbyPlaces(
                currentLocation: location ?? referenceLocation,
                districtFilter: shouldForceColomboOnly ? "Colombo" : nil
            )
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
                    isMenuOpen = false
                    selectedTab = .profile
                    contentTab = .profile
                }
            } label: {
                Image(systemName: "person.fill")
                    .font(.subheadline)
                    .foregroundStyle(Color.travelTitle)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(.white.opacity(0.85)))
            }
            .buttonStyle(.plain)
        }
    }

    private var homeBanner: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.travelPrimary.opacity(0.95), Color.green.opacity(0.7)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            WeatherBannerBackground(imageName: weatherViewModel.weather.backgroundImageName)

            VStack(alignment: .leading, spacing: 6) {
                Text("• Today in \(weatherViewModel.weather.cityName)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))

                Text("\(weatherViewModel.weather.title) in \(weatherViewModel.weather.cityName) \(weatherViewModel.weather.isRainy ? "🌧️" : "☀️")")
                    .font(.headline)
                    .foregroundStyle(.white)

                Text("\(weatherViewModel.weather.temperatureCelsius)°C • \(weatherViewModel.weather.description)")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
            }
            .padding(14)
        }
        .frame(height: 130)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        )
    }

    private var manualPlanShortcut: some View {
        Button {
            selectedTab = .myTrip
            contentTab = .myTrip
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "calendar.badge.plus")
                    .font(.title3)
                    .foregroundStyle(Color.travelPrimary)
                    .frame(width: 42, height: 42)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.travelPrimary.opacity(0.12))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text("Plan your adventure")
                        .font(.headline)
                        .foregroundStyle(Color.travelTitle)
                    Text("Build your trip manually with your own stops")
                        .font(.subheadline)
                        .foregroundStyle(Color.travelBody)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.travelPrimary)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.9))
            )
        }
        .buttonStyle(.plain)
    }

    private var sortedPlaces: [PlaceCardItem] {
        return HomeMockData.explorePlaces.sorted { left, right in
            let leftDistance = referenceLocation.distance(from: CLLocation(latitude: left.coordinate.latitude, longitude: left.coordinate.longitude))
            let rightDistance = referenceLocation.distance(from: CLLocation(latitude: right.coordinate.latitude, longitude: right.coordinate.longitude))
            return leftDistance < rightDistance
        }
    }

    private var nearbyPlacesToShow: [PlaceCardItem] {
        if !nearbyPlacesViewModel.nearbyPlaces.isEmpty {
            return Array(nearbyPlacesViewModel.nearbyPlaces.prefix(4))
        }
        if shouldForceColomboOnly {
            return Array(sortedPlaces.filter { $0.subtitle.caseInsensitiveCompare("Colombo") == .orderedSame }.prefix(4))
        }
        return Array(sortedPlaces.prefix(4))
    }

    private var allNearbyPlaces: [PlaceCardItem] {
        if !nearbyPlacesViewModel.allPlaces.isEmpty {
            return nearbyPlacesViewModel.allPlaces
        }
        return sortedPlaces
    }

    private func distanceText(for coordinate: CLLocationCoordinate2D) -> String {
        let placeLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let distanceInKm = referenceLocation.distance(from: placeLocation) / 1000
        return String(format: "%.1f km away", distanceInKm)
    }

    private var shouldForceColomboOnly: Bool {
        locationManager.authorizationStatus == .denied
            || locationManager.authorizationStatus == .restricted
            || locationManager.location == nil
    }

    private var referenceLocation: CLLocation {
        if let location = locationManager.location {
            return location
        }
        return CLLocation(latitude: fallbackCoordinate.latitude, longitude: fallbackCoordinate.longitude)
    }
}

private struct WeatherBannerBackground: View {
    let imageName: String

    var body: some View {
        Group {
            if let uiImage = loadImage(named: imageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .opacity(0.5)
            } else {
                Color.clear
            }
        }
    }

    private func loadImage(named name: String) -> UIImage? {
        let directCandidates = [
            name,
            "\(name).JPG",
            "\(name).jpg",
            "Images/\(name).JPG",
            "Images/\(name).jpg",
            "Assets/Images/\(name).JPG",
            "Assets/Images/\(name).jpg"
        ]

        for candidate in directCandidates {
            if let image = UIImage(named: candidate) {
                return image
            }
        }

        let searchDirectories: [String?] = [nil, "Images", "Assets", "Assets/Images"]
        let extensions = ["JPG", "jpg", "JPEG", "jpeg"]

        for directory in searchDirectories {
            for fileExtension in extensions {
                if let path = Bundle.main.path(forResource: name, ofType: fileExtension, inDirectory: directory),
                   let image = UIImage(contentsOfFile: path) {
                    return image
                }
            }
        }

        return nil
    }
}
