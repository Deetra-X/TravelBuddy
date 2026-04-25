import SwiftUI
import MapKit
import CoreLocation

struct HomeScreen: View {
    private struct QuickPlanPlaceRecord: Decodable {
        let category: String
        let district: String
        let name: String
        let description: String
        let rating: Double
        let imageURLString: String?
        let latitude: Double
        let longitude: Double

        enum CodingKeys: String, CodingKey {
            case category
            case district
            case name
            case description
            case rating
            case imageURLString = "image_url"
            case latitude
            case longitude
        }

        func toQuickPlanPlace(resolvedImageURLString: String? = nil) -> QuickPlanDBPlace {
            QuickPlanDBPlace(
                category: category,
                name: name,
                district: district,
                description: description,
                rating: rating,
                imageURLString: resolvedImageURLString ?? imageURLString,
                coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            )
        }
    }

    private struct ExperiencePlacesSelection: Identifiable {
        let id = UUID()
        let places: [PlaceCardItem]
    }

    var onLogout: () -> Void

    @EnvironmentObject private var sessionManager: SessionManager
    @EnvironmentObject private var ongoingTripViewModel: OngoingTripViewModel

    @StateObject private var locationManager = UserLocationManager()
    @StateObject private var weatherViewModel = WeatherViewModel()
    @StateObject private var nearbyPlacesViewModel = NearbyPlacesViewModel()
    @StateObject private var preferencesViewModel = UserPreferencesViewModel()
    @State private var selectedTab: HomeTab = .home
    @State private var contentTab: HomeTab = .home
    @State private var isMenuOpen = false
    @State private var showAdvancedSettings = false
    @State private var showAllNearbyPlaces = false
    @State private var quickPlans: [QuickPlanItem] = []
    @State private var quickPlanDBPlaces: [QuickPlanDBPlace] = []
    @State private var selectedQuickPlan: QuickPlanItem?
    @State private var selectedExperienceSelection: ExperiencePlacesSelection?
    @State private var experienceTiles: [ExperienceItem] = HomeMockData.experiences
    @State private var experienceTileRules: [ExperienceTileRule] = ExperienceTileRule.defaultRules
    @StateObject private var experienceTileService = ExperienceTileLoader()

    private let fallbackCoordinate = CLLocationCoordinate2D(latitude: 6.906555, longitude: 79.87071)

    var body: some View {
        ZStack {
            Color.travelBackground.ignoresSafeArea()

            Group {
                if contentTab == .myTrip {
                    ManualTripPlannerScreen {
                        selectedTab = .journey
                        contentTab = .journey
                    }
                } else if contentTab == .journey {
                    JourneyTripsScreen {
                        selectedTab = .myTrip
                        contentTab = .myTrip
                    }
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
                                if quickPlans.isEmpty {
                                    Text("No quick plans yet. Add places to your database and try again.")
                                        .font(.subheadline)
                                        .foregroundStyle(Color.travelBody)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.vertical, 8)
                                } else {
                                    ForEach(quickPlans) { item in
                                        QuickPlanCard(item: item) {
                                            selectedQuickPlan = item
                                        }
                                    }
                                }
                            }

                            HomeSectionHeader(title: "Experiences You’ll Love")

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                ForEach(experienceTiles) { item in
                                    ExperienceCard(item: item) {
                                        selectedExperienceSelection = ExperiencePlacesSelection(
                                            places: item.matchedPlaces.isEmpty ? allNearbyPlaces : item.matchedPlaces
                                        )
                                    }
                                }
                            }

                            HomeSectionHeader(title: "Ongoing trip", trailingText: activeOngoingTripCardItem == nil ? nil : "Active now")
                            if let ongoingTripItem = activeOngoingTripCardItem {
                                OngoingTripCard(item: ongoingTripItem) {
                                    selectedTab = .journey
                                    contentTab = .journey
                                }
                            } else {
                                noOngoingTripCard
                            }
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
            } onLogout: {
                showAdvancedSettings = false
                onLogout()
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
        .fullScreenCover(item: $selectedExperienceSelection) { selection in
            NearbyPlacesListScreen(
                items: selection.places,
                currentLocation: referenceLocation,
                onClose: {
                    selectedExperienceSelection = nil
                }
            )
        }
        .sheet(item: $selectedQuickPlan) { plan in
            QuickPlanDetailScreen(
                plan: plan,
                onClose: {
                    selectedQuickPlan = nil
                },
                onTripPlanned: {
                    selectedQuickPlan = nil
                    selectedTab = .journey
                    contentTab = .journey
                }
            )
            .environmentObject(sessionManager)
            .environmentObject(ongoingTripViewModel)
        }
        .onAppear {
            locationManager.requestAndStart()
            weatherViewModel.refreshIfNeeded(from: locationManager.location)
            nearbyPlacesViewModel.loadPlacesIfNeeded(
                currentLocation: referenceLocation,
                districtFilter: shouldForceColomboOnly ? "Colombo" : nil
            )

            preferencesViewModel.loadUserPreferences()
            refreshQuickPlans()

            Task {
                await loadQuickPlanPlacesFromDB()
                refreshQuickPlans()
            }

            if let session = sessionManager.currentSession {
                Task {
                    await ongoingTripViewModel.loadTrips(session: session, force: false)
                }
            }
        }
        .onChange(of: preferencesViewModel.userPreferences.selectedActivityIds) {
            refreshQuickPlans()
        }
        .onReceive(locationManager.$location) { location in
            weatherViewModel.refreshIfNeeded(from: location)
            nearbyPlacesViewModel.updateNearbyPlaces(
                currentLocation: location ?? referenceLocation,
                districtFilter: shouldForceColomboOnly ? "Colombo" : nil
            )
        }
        .onReceive(nearbyPlacesViewModel.$allPlaces) { places in
            guard !places.isEmpty else { return }
            experienceTiles = buildExperienceTiles(from: places)
            refreshQuickPlans()
        }
        .task {
            await experienceTileService.loadRules()
            experienceTileRules = experienceTileService.rules
            experienceTiles = buildExperienceTiles(from: allNearbyPlaces)
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

    private var activeOngoingTripCardItem: OngoingTripItem? {
        guard let latest = ongoingTripViewModel.latestTrip else {
            return nil
        }

        return OngoingTripItem(
            title: latest.title,
            progressText: latest.displayProgressText,
            progress: latest.resolvedProgress
        )
    }

    private var noOngoingTripCard: some View {
        Button {
            selectedTab = .myTrip
            contentTab = .myTrip
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "map")
                    .font(.title3)
                    .foregroundStyle(Color.travelPrimary)
                    .frame(width: 42, height: 42)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.travelPrimary.opacity(0.12))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text("No ongoing trips")
                        .font(.headline)
                        .foregroundStyle(Color.travelTitle)
                    Text("Start planning and your trip will appear here")
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

    private func refreshQuickPlans() {
        let selectedActivities = preferencesViewModel.userPreferences.selectedActivities
        quickPlans = QuickPlansGenerator.generatePlans(
            from: selectedActivities,
            categorizedPlaces: quickPlanDBPlaces
        )
    }

    private func loadQuickPlanPlacesFromDB() async {
        guard AuthEndpoints.isConfigured,
              let baseURL = AuthEndpoints.baseURL else {
            quickPlanDBPlaces = []
            return
        }

        guard var components = URLComponents(url: baseURL.appending(path: "/rest/v1/manual_planner_places"), resolvingAgainstBaseURL: false) else {
            quickPlanDBPlaces = []
            return
        }

        components.queryItems = [
            URLQueryItem(name: "select", value: "category,district,name,description,rating,image_url,latitude,longitude"),
            URLQueryItem(name: "order", value: "rating.desc")
        ]

        guard let url = components.url else {
            quickPlanDBPlaces = []
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")

        do {
            async let places = NearbyPlacesService().fetchPlaces()
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                quickPlanDBPlaces = []
                return
            }

            let decoded = try JSONDecoder().decode([QuickPlanPlaceRecord].self, from: data)
            let placeCandidates = (try? await places) ?? []
            quickPlanDBPlaces = decoded.map { record in
                let resolved = resolveQuickPlanImageURLString(for: record, candidates: placeCandidates)
                return record.toQuickPlanPlace(resolvedImageURLString: resolved)
            }
        } catch {
            quickPlanDBPlaces = []
        }
    }

    private func resolveQuickPlanImageURLString(for record: QuickPlanPlaceRecord, candidates: [PlaceCardItem]) -> String? {
        if let source = record.imageURLString,
           !isPlaceholderImageURLString(source) {
            return source
        }

        let targetName = normalizePlannerText(record.name)
        let targetDistrict = normalizePlannerText(record.district)

        let scored = candidates.compactMap { candidate -> (URL, Double)? in
            guard let candidateURL = candidate.imageURL,
                  !isPlaceholderImageURL(candidateURL) else { return nil }

            let candidateName = normalizePlannerText(candidate.name)
            let candidateDistrict = normalizePlannerText(candidate.subtitle)

            let nameScore: Double
            if candidateName == targetName {
                nameScore = 0.0
            } else if candidateName.contains(targetName) || targetName.contains(candidateName) {
                nameScore = 0.35
            } else {
                let targetTokens = Set(targetName.split(separator: " ").map(String.init))
                let candidateTokens = Set(candidateName.split(separator: " ").map(String.init))
                let overlap = targetTokens.intersection(candidateTokens).count
                guard overlap > 0 else { return nil }
                nameScore = 0.8
            }

            let districtBonus = (candidateDistrict == targetDistrict) ? -0.2 : 0.0
            let coordinateScore = min(
                hypot(candidate.coordinate.latitude - record.latitude, candidate.coordinate.longitude - record.longitude),
                1.0
            )
            let finalScore = nameScore + districtBonus + coordinateScore

            guard finalScore <= 1.35 else { return nil }
            return (candidateURL, finalScore)
        }

        return scored.min(by: { $0.1 < $1.1 })?.0.absoluteString
    }

    private func normalizePlannerText(_ value: String) -> String {
        value
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private func isPlaceholderImageURLString(_ value: String) -> Bool {
        guard let url = URL(string: value) else { return false }
        return isPlaceholderImageURL(url)
    }

    private func isPlaceholderImageURL(_ url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        return host.contains("example.com")
    }

    private var homeBanner: some View {
        ZStack(alignment: .leading) {
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

    private func buildExperienceTiles(from places: [PlaceCardItem]) -> [ExperienceItem] {
        let rules = experienceTileRules.isEmpty ? ExperienceTileRule.defaultRules : experienceTileRules
        return rules.map { rule in
            let matched = matchedPlaces(from: places, rule: rule)
            return tile(rule: rule, with: matched)
        }
    }

    private func matchedPlaces(from places: [PlaceCardItem], rule: ExperienceTileRule) -> [PlaceCardItem] {
        places
            .filter { place in
                let haystack = "\(place.name) \(place.description)".lowercased()
                let district = place.subtitle.lowercased()

                let matchesName = rule.nameKeywords.contains { haystack.contains($0.lowercased()) }
                let matchesDescription = rule.descriptionKeywords.contains { haystack.contains($0.lowercased()) }
                let matchesDistrict = rule.districtKeywords.contains { district.contains($0.lowercased()) }

                return matchesName || matchesDescription || matchesDistrict
            }
            .sorted {
                if $0.rating == $1.rating {
                    return $0.name < $1.name
                }
                return $0.rating > $1.rating
            }
            .prefix(8)
            .map { $0 }
    }

    private func tile(rule: ExperienceTileRule, with places: [PlaceCardItem]) -> ExperienceItem {
        let defaultRule = ExperienceTileRule.defaultRules.first(where: { $0.tileKey == rule.tileKey })
        let resolvedImageName = rule.imageName ?? defaultRule?.imageName
        let resolvedAccentHex = rule.accentHex.isEmpty ? (defaultRule?.accentHex ?? "0D47A1") : rule.accentHex
        let resolvedIcon = rule.icon.isEmpty ? (defaultRule?.icon ?? "star.fill") : rule.icon
        let resolvedTitle = rule.title.isEmpty ? (defaultRule?.title ?? rule.tileKey) : rule.title
        let resolvedSubtitle = rule.subtitle.isEmpty ? (defaultRule?.subtitle ?? "") : rule.subtitle

        guard let lead = places.first else {
            return ExperienceItem(
                title: resolvedTitle,
                subtitle: resolvedSubtitle,
                icon: resolvedIcon,
                accentHex: resolvedAccentHex,
                imageName: resolvedImageName,
                matchedPlaces: []
            )
        }

        return ExperienceItem(
            title: resolvedTitle,
            subtitle: "\(lead.name) • \(lead.subtitle)",
            icon: resolvedIcon,
            accentHex: resolvedAccentHex,
            imageName: resolvedImageName,
            imageURLString: lead.imageURL?.absoluteString,
            matchedPlaces: places
        )
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
