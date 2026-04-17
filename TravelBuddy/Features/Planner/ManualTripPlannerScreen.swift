import SwiftUI
import CoreLocation
import Combine
import MapKit

struct ManualTripPlannerScreen: View {
    private enum PlannerStep {
        case category
        case destinations
    }

    @State private var step: PlannerStep = .category
    @State private var selectedCategories: Set<ManualPlanCategory> = []
    @State private var selectedDestinationKeys: Set<String> = []
    @State private var selectedTripDays: Int = 1
    @State private var showingPlanDates: Bool = false
    @State private var showingPlannedTrip: Bool = false

    var body: some View {
        ZStack {
            Color.travelBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    if step == .category {
                        Text("What's your adventure category?")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Color.travelTitle)

                        Text("Select up to 3 categories")
                            .font(.subheadline)
                            .foregroundStyle(Color.travelBody)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(ManualPlanCategory.allCases) { category in
                                ManualPlanCategoryCard(
                                    category: category,
                                    isSelected: selectedCategories.contains(category),
                                    isDisabled: isCategoryDisabled(category),
                                    imageName: category.assetName
                                ) {
                                    toggleCategory(category)
                                }
                            }
                        }
                        .padding(.top, 4)

                        Text("Selected: \(selectedCategories.count)/3")
                            .font(.caption)
                            .foregroundStyle(Color.travelBody)
                    } else {
                        HStack {
                            Text("Select destinations")
                                .font(.title2.weight(.bold))
                                .foregroundStyle(Color.travelTitle)

                            Spacer()

                            Button {
                                step = .category
                            } label: {
                                Text("Edit categories")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color.travelPrimary)
                            }
                            .buttonStyle(.plain)
                        }

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(selectedCategoriesSorted, id: \.id) { category in
                                    CategoryNameIndicator(category: category, isHighlighted: true)
                                }
                            }
                            .padding(.vertical, 2)
                        }

                        Text("\(selectedDestinationKeys.count) destinations selected")
                            .font(.caption)
                            .foregroundStyle(Color.travelBody)

                        if !selectedDestinationKeys.isEmpty {
                            Text("Trip duration: \(selectedTripDays) \(selectedTripDays == 1 ? "day" : "days")")
                                .font(.caption)
                                .foregroundStyle(Color.travelBody)
                        }

                        ForEach(selectedCategoriesSorted, id: \.id) { category in
                            VStack(alignment: .leading, spacing: 10) {
                                Text(category.rawValue)
                                    .font(.headline)
                                    .foregroundStyle(Color.travelTitle)

                                ForEach(filteredPlaces(for: category)) { place in
                                    ManualPlanPlaceCard(
                                        place: place,
                                        isSelected: selectedDestinationKeys.contains(placeSelectionKey(place)),
                                        onToggleSelection: {
                                            toggleDestination(place)
                                        }
                                    )
                                }
                            }
                        }
                    }
                }
                .padding(16)
                .padding(.top, 8)
            }
        }
        .safeAreaInset(edge: .bottom) {
            if step == .category {
                Button {
                    pruneSelectedDestinations()
                    step = .destinations
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.travelPrimary)
                        )
                }
                .buttonStyle(.plain)
                .disabled(selectedCategories.isEmpty)
                .opacity(selectedCategories.isEmpty ? 0.55 : 1)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 8)
                .background(Color.travelBackground.opacity(0.94))
            } else {
                Button {
                    enforceDaySelectionRules()
                    showingPlanDates = true
                } label: {
                    Text("Plan Dates")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.travelPrimary)
                        )
                }
                .buttonStyle(.plain)
                .disabled(selectedDestinationKeys.isEmpty)
                .opacity(selectedDestinationKeys.isEmpty ? 0.55 : 1)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 8)
                .background(Color.travelBackground.opacity(0.94))
            }
        }
        .fullScreenCover(isPresented: $showingPlanDates) {
            PlanDatesFullScreen(
                selectedTripDays: $selectedTripDays,
                allowedDayOptions: allowedDayOptions,
                destinationCount: selectedDestinationKeys.count,
                onDone: {
                    showingPlannedTrip = true
                }
            )
        }
        .fullScreenCover(isPresented: $showingPlannedTrip) {
            PlannedTripScreen(initialDays: selectedTripDays, selectedDestinations: selectedDestinations)
        }
    }

    private var allowedDayOptions: [Int] {
        let destinationCount = selectedDestinationKeys.count

        if destinationCount == 1 {
            return [1]
        }

        if destinationCount > 2 {
            return Array(2...15)
        }

        return Array(1...15)
    }

    private var selectedCategoriesSorted: [ManualPlanCategory] {
        ManualPlanCategory.allCases.filter { selectedCategories.contains($0) }
    }

    private var selectedDestinations: [ManualPlanPlace] {
        let selectedKeys = selectedDestinationKeys
        return ManualPlannerSeedData.places.filter { selectedKeys.contains(placeSelectionKey($0)) }
    }

    private func filteredPlaces(for category: ManualPlanCategory) -> [ManualPlanPlace] {
        ManualPlannerSeedData.places.filter { $0.category == category }
    }

    private func toggleCategory(_ category: ManualPlanCategory) {
        withAnimation(.easeInOut(duration: 0.22)) {
            if selectedCategories.contains(category) {
                selectedCategories.remove(category)
            } else if selectedCategories.count < 3 {
                selectedCategories.insert(category)
            }
        }
    }

    private func isCategoryDisabled(_ category: ManualPlanCategory) -> Bool {
        selectedCategories.count >= 3 && !selectedCategories.contains(category)
    }

    private func placeSelectionKey(_ place: ManualPlanPlace) -> String {
        "\(place.category.dbValue)-\(place.name)-\(place.district)"
    }

    private func toggleDestination(_ place: ManualPlanPlace) {
        let key = placeSelectionKey(place)
        if selectedDestinationKeys.contains(key) {
            selectedDestinationKeys.remove(key)
        } else {
            selectedDestinationKeys.insert(key)
        }

        enforceDaySelectionRules()
    }

    private func pruneSelectedDestinations() {
        let allowedKeys = Set(
            ManualPlannerSeedData.places
                .filter { selectedCategories.contains($0.category) }
                .map(placeSelectionKey)
        )

        selectedDestinationKeys = selectedDestinationKeys.intersection(allowedKeys)
        enforceDaySelectionRules()
    }

    private func enforceDaySelectionRules() {
        let options = allowedDayOptions
        if !options.contains(selectedTripDays), let minimumAllowed = options.first {
            selectedTripDays = minimumAllowed
        }
    }
}

private struct PlanDatesFullScreen: View {
    @Binding var selectedTripDays: Int
    let allowedDayOptions: [Int]
    let destinationCount: Int
    var onDone: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.travelBackground.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("How many days?")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Color.travelTitle)

                        Text(ruleMessage)
                            .font(.subheadline)
                            .foregroundStyle(Color.travelBody)
                    }
                    .padding(.top, 8)

                    Spacer(minLength: 8)

                    VStack(spacing: 12) {
                        Text("\(selectedTripDays) \(selectedTripDays == 1 ? "day" : "days")")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.travelTitle)

                        Text("Countdown from 15: \(max(0, 15 - selectedTripDays))")
                            .font(.caption)
                            .foregroundStyle(Color.travelBody)

                        Picker("Trip Days", selection: $selectedTripDays) {
                            ForEach(allowedDayOptions, id: \.self) { day in
                                Text("\(day)")
                                    .font(.title3.weight(.semibold))
                                    .tag(day)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 200)
                        .clipped()
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color.white.opacity(0.72))
                        )
                    }
                    .frame(maxWidth: .infinity)

                    Spacer(minLength: 8)

                    Button {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            onDone()
                        }
                    } label: {
                        Text("Create Plan")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.travelPrimary)
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundStyle(Color.travelPrimary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.travelPrimary)
                }
            }
        }
    }

    private var ruleMessage: String {
        if destinationCount == 1 {
            return "For one destination, only 1 day is available."
        }

        if destinationCount > 2 {
            return "For 3+ destinations, select at least 2 days."
        }

        return "Choose your trip duration."
    }
}

private struct PlannedTripScreen: View {
    @State private var selectedDayIndex: Int = 0
    @State private var dayPlans: [TripDayPlan]
    @State private var showingDestinationPicker: Bool = false
    @State private var showingPlannedRoute: Bool = false
    @StateObject private var plannerLocationManager = PlannerLocationManager()

    let selectedDestinations: [ManualPlanPlace]

    @Environment(\.dismiss) private var dismiss

    init(initialDays: Int, selectedDestinations: [ManualPlanPlace]) {
        self.selectedDestinations = selectedDestinations
        let safeDays = max(1, initialDays)
        _dayPlans = State(initialValue: (1...safeDays).map { day in
            TripDayPlan(dayNumber: day, date: Calendar.current.date(byAdding: .day, value: day - 1, to: Date()) ?? Date(), locations: [])
        })
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.travelBackground.ignoresSafeArea()

                VStack(spacing: 14) {
                    dayTabs
                    itineraryTimeline
                }
                .padding(16)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundStyle(Color.travelPrimary)
                }
            }
            .onAppear {
                plannerLocationManager.requestLocationAccess()
            }
            .navigationDestination(isPresented: $showingPlannedRoute) {
                PlannedTripRouteScreen(dayPlans: dayPlans)
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    showingPlannedRoute = true
                } label: {
                    Text("Plan Trip")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.travelPrimary)
                        )
                }
                .buttonStyle(.plain)
                .disabled(dayPlans.allSatisfy { $0.locations.isEmpty })
                .opacity(dayPlans.allSatisfy { $0.locations.isEmpty } ? 0.55 : 1)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 8)
                .background(Color.travelBackground.opacity(0.94))
            }
        }
    }

    private var dayTabs: some View {
        HStack(spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(dayPlans.indices, id: \.self) { index in
                        let dayPlan = dayPlans[index]
                        Button {
                            selectedDayIndex = index
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Day \(String(format: "%02d", dayPlan.dayNumber))")
                                    .font(.headline)
                                Text(dayPlan.date, style: .date)
                                    .font(.caption)
                            }
                            .foregroundStyle(selectedDayIndex == index ? Color.travelPrimary : Color.travelTitle)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(selectedDayIndex == index ? Color.travelPrimary.opacity(0.16) : Color.white.opacity(0.68))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Button {
                addNewDay()
            } label: {
                Image(systemName: "plus")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.travelPrimary)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Color.travelPrimary.opacity(0.12))
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.travelPrimary.opacity(0.8), lineWidth: 1.5)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private var itineraryTimeline: some View {
        let dayPlan = dayPlans[selectedDayIndex]

        return ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Each destination can be added only once across all days.")
                        .font(.caption)
                        .foregroundStyle(Color.travelBody)

                    Text("\(remainingDestinationsCount) of \(selectedDestinations.count) destinations left for this trip")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.travelPrimary)

                    if remainingDestinationsCount == 0 {
                        Text("All selected destinations are already planned. Remaining days stay available for your next trip.")
                            .font(.caption)
                            .foregroundStyle(Color.travelBody)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if dayPlan.locations.isEmpty {
                    Text("No locations yet for this day.")
                        .font(.subheadline)
                        .foregroundStyle(Color.travelBody)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                } else {
                    ForEach(dayPlan.locations.indices, id: \.self) { index in
                        HStack(alignment: .top, spacing: 12) {
                            VStack(spacing: 0) {
                                Circle()
                                    .fill(Color.travelPrimary.opacity(0.9))
                                    .frame(width: 26, height: 26)
                                    .overlay(
                                        Text("\(index + 1)")
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(.white)
                                    )

                                if index < dayPlan.locations.count - 1 {
                                    Rectangle()
                                        .fill(Color.travelPrimary.opacity(0.5))
                                        .frame(width: 2, height: 56)
                                        .padding(.top, 6)
                                }
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text(dayPlan.locations[index].title)
                                    .font(.headline)
                                    .foregroundStyle(Color.travelTitle)
                                Text(dayPlan.locations[index].timeRange)
                                    .font(.caption)
                                    .foregroundStyle(Color.travelBody)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.white.opacity(0.86))
                            )
                        }
                    }
                }

                Button {
                    showingDestinationPicker = true
                } label: {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add Location")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(Color.travelPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(style: StrokeStyle(lineWidth: 1.2, dash: [6, 4]))
                            .foregroundStyle(Color.travelPrimary.opacity(0.65))
                    )
                }
                .buttonStyle(.plain)
                .disabled(orderedAvailableDestinationsForSelectedDay.isEmpty)
                .opacity(orderedAvailableDestinationsForSelectedDay.isEmpty ? 0.5 : 1)
                .confirmationDialog("Add a destination", isPresented: $showingDestinationPicker, titleVisibility: .visible) {
                    ForEach(orderedAvailableDestinationsForSelectedDay) { place in
                        Button(place.name) {
                            addLocationToSelectedDay(place)
                        }
                    }

                    Button("Cancel", role: .cancel) {}
                } message: {
                    if orderedAvailableDestinationsForSelectedDay.isEmpty {
                        Text("All selected destinations are already assigned in this trip.")
                    } else {
                        Text("Closest places from your current location are listed first.")
                    }
                }
            }
            .padding(.top, 2)
        }
    }

    private func addNewDay() {
        let newDayNumber = dayPlans.count + 1
        let newDate = Calendar.current.date(byAdding: .day, value: newDayNumber - 1, to: Date()) ?? Date()

        dayPlans.append(
            TripDayPlan(
                dayNumber: newDayNumber,
                date: newDate,
                locations: []
            )
        )

        selectedDayIndex = dayPlans.count - 1
    }

    private var usedDestinationKeys: Set<String> {
        Set(dayPlans.flatMap { $0.locations.map(\.destinationKey) })
    }

    private var remainingDestinationsCount: Int {
        selectedDestinations.filter { !usedDestinationKeys.contains(destinationKey(for: $0)) }.count
    }

    private var availableDestinationsForSelectedDay: [ManualPlanPlace] {
        selectedDestinations.filter { !usedDestinationKeys.contains(destinationKey(for: $0)) }
    }

    private var orderedAvailableDestinationsForSelectedDay: [ManualPlanPlace] {
        var remaining = availableDestinationsForSelectedDay
        var ordered: [ManualPlanPlace] = []

        var referenceLocation: CLLocation?
        if dayPlans.indices.contains(selectedDayIndex),
           let last = dayPlans[selectedDayIndex].locations.last {
            referenceLocation = CLLocation(latitude: last.latitude, longitude: last.longitude)
        } else {
            referenceLocation = plannerLocationManager.currentLocation
        }

        while !remaining.isEmpty {
            if let reference = referenceLocation {
                let closestIndex = remaining.indices.min {
                    distance(from: reference, to: remaining[$0]) < distance(from: reference, to: remaining[$1])
                } ?? 0

                let next = remaining.remove(at: closestIndex)
                ordered.append(next)
                referenceLocation = CLLocation(latitude: next.latitude, longitude: next.longitude)
            } else {
                let fallback = remaining.removeFirst()
                ordered.append(fallback)
            }
        }

        return ordered
    }

    private func destinationKey(for place: ManualPlanPlace) -> String {
        "\(place.category.dbValue)-\(place.name)-\(place.district)"
    }

    private func distance(from base: CLLocation, to place: ManualPlanPlace) -> CLLocationDistance {
        let destination = CLLocation(latitude: place.latitude, longitude: place.longitude)
        return base.distance(from: destination)
    }

    private func addLocationToSelectedDay(_ place: ManualPlanPlace) {
        guard dayPlans.indices.contains(selectedDayIndex) else { return }

        dayPlans[selectedDayIndex].locations.append(
            TripLocationStop(
                title: place.name,
                timeRange: place.district,
                rating: place.rating,
                latitude: place.latitude,
                longitude: place.longitude,
                destinationKey: destinationKey(for: place),
                description: place.description,
                imageURL: place.imageURL
            )
        )
    }
}

private struct PlannedTripRouteScreen: View {
    let dayPlans: [TripDayPlan]

    private var routeStops: [TripLocationStop] {
        dayPlans.flatMap(\.locations)
    }

    var body: some View {
        ZStack {
            Color.travelBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    ForEach(routeStops.indices, id: \.self) { index in
                        HStack(alignment: .top, spacing: 8) {
                            VStack(spacing: 0) {
                                Circle()
                                    .fill(Color.travelPrimary.opacity(0.95))
                                    .frame(width: 20, height: 20)
                                    .overlay(
                                        Text("\(index + 1)")
                                            .font(.caption2.weight(.semibold))
                                            .foregroundStyle(.white)
                                    )

                                if index < routeStops.count - 1 {
                                    Rectangle()
                                        .fill(Color.travelPrimary.opacity(0.5))
                                        .frame(width: 2, height: 112)
                                        .clipShape(Capsule())
                                        .padding(.top, 6)
                                }
                            }
                            .frame(width: 24)

                            VStack(spacing: 6) {
                                NavigationLink {
                                    PlaceDetailsScreen(
                                        placeName: routeStops[index].title,
                                        district: routeStops[index].timeRange,
                                        fallbackDescription: routeStops[index].description,
                                        fallbackImageURL: routeStops[index].imageURL,
                                        fallbackRating: routeStops[index].rating,
                                        fallbackLatitude: routeStops[index].latitude,
                                        fallbackLongitude: routeStops[index].longitude
                                    )
                                } label: {
                                    DestinationCard(stop: routeStops[index])
                                }
                                .buttonStyle(.plain)

                                Button {
                                    if index < routeStops.count - 1 {
                                        openDirections(from: routeStops[index], to: routeStops[index + 1])
                                    } else {
                                        openDirectionsToDestination(routeStops[index])
                                    }
                                } label: {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(style: StrokeStyle(lineWidth: 1.0, dash: [6, 4]))
                                        .foregroundStyle(Color.travelBody.opacity(0.42))
                                        .frame(height: 60) //meka
                                        .overlay(
                                            Text("Directions")
                                                .font(.footnote.weight(.semibold))
                                                .foregroundStyle(Color.travelBody.opacity(0.88))
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.leading, 14)
                .padding(.trailing, 24)
                .padding(.vertical, 14)
            }
        }
        .navigationTitle("Trip Plan")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func openDirections(from sourceStop: TripLocationStop, to destinationStop: TripLocationStop) {
        let sourceItem = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: sourceStop.latitude, longitude: sourceStop.longitude)))
        sourceItem.name = sourceStop.title

        let destinationItem = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: destinationStop.latitude, longitude: destinationStop.longitude)))
        destinationItem.name = destinationStop.title

        MKMapItem.openMaps(
            with: [sourceItem, destinationItem],
            launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        )
    }

    private func openDirectionsToDestination(_ stop: TripLocationStop) {
        let destinationItem = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: stop.latitude, longitude: stop.longitude)))
        destinationItem.name = stop.title
        destinationItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
}

private struct DestinationCard: View {
    let stop: TripLocationStop

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.travelPrimary.opacity(0.22))

                if let imageURL = stop.imageURL {
                    AsyncImage(url: imageURL) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .scaledToFill()
                        }
                    }
                }

                VStack {
                    HStack {
                        Spacer()

                        DestinationWishlistButton(
                            source: .manualPlannerPlaces,
                            placeName: stop.title,
                            district: stop.timeRange,
                            imageURL: stop.imageURL
                        )
                        .padding(8)
                    }

                    Spacer()
                }
            }
            .frame(height: 62)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(stop.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.travelTitle)
                    Text(stop.timeRange)
                        .font(.footnote)
                        .foregroundStyle(Color.travelPrimary)
                }

                Spacer()

                Image(systemName: "chevron.right.circle")
                    .font(.subheadline)
                    .foregroundStyle(Color.travelBody.opacity(0.85))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.92))
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct DestinationScreen: View {
    let stop: TripLocationStop

    var body: some View {
        ZStack {
            Color.travelBackground.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 14) {
                Text("Destination")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.travelTitle)

                NavigationLink {
                    DestinationDescriptionScreen(stop: stop)
                } label: {
                    HStack {
                        Text(stop.title)
                            .font(.headline)
                            .foregroundStyle(Color.travelTitle)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(Color.travelBody)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.white.opacity(0.9))
                    )
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(16)
        }
        .navigationTitle("Destination")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct DestinationDescriptionScreen: View {
    let stop: TripLocationStop

    var body: some View {
        ZStack {
            Color.travelBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(stop.title)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.travelTitle)

                    Text(stop.timeRange)
                        .font(.subheadline)
                        .foregroundStyle(Color.travelPrimary)

                    Text(stop.description)
                        .font(.body)
                        .foregroundStyle(Color.travelBody)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
            }
        }
        .navigationTitle("Description")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct TripDayPlan {
    var dayNumber: Int
    var date: Date
    var locations: [TripLocationStop]
}

private struct TripLocationStop {
    var title: String
    var timeRange: String
    var rating: Double
    var latitude: Double
    var longitude: Double
    var destinationKey: String
    var description: String
    var imageURL: URL?
}

private final class PlannerLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var currentLocation: CLLocation?

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestLocationAccess() {
        let status = manager.authorizationStatus
        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
            manager.requestLocation()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            break
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
}

private struct ManualPlanCategoryCard: View {
    let category: ManualPlanCategory
    let isSelected: Bool
    let isDisabled: Bool
    let imageName: String
    var onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.travelPrimary.opacity(0.28), Color.teal.opacity(0.22)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                if let uiImage = loadLocalImage(named: imageName) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .opacity(0.96)
                }

                LinearGradient(
                    colors: [.clear, .black.opacity(0.5)],
                    startPoint: .center,
                    endPoint: .bottom
                )

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .padding(8)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                }
            }
            .frame(height: 128)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(alignment: .bottomLeading) {
                CategoryNameIndicator(category: category)
                    .padding(10)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? Color.travelPrimary : .white.opacity(0.35), lineWidth: isSelected ? 2 : 1)
            )
            .opacity(isDisabled ? 0.42 : 1)
            .scaleEffect(isSelected ? 1.03 : 1.0)
            .animation(.easeInOut(duration: 0.22), value: isSelected)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }

    private func loadLocalImage(named name: String) -> UIImage? {
        let candidates = [
            name,
            "\(name).JPG",
            "\(name).jpg",
            "Images/\(name).JPG",
            "Images/\(name).jpg",
            "Assets/Images/\(name).JPG",
            "Assets/Images/\(name).jpg"
        ]

        for candidate in candidates {
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

private struct CategoryNameIndicator: View {
    let category: ManualPlanCategory
    var isHighlighted: Bool = false

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: category.icon)
                .font(.caption2.weight(.semibold))

            Text(category.rawValue)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            Capsule(style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    .white.opacity(isHighlighted ? 0.42 : 0.34),
                                    .white.opacity(isHighlighted ? 0.16 : 0.1),
                                    .clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
                .overlay(
                    Capsule(style: .continuous)
                        .fill(isHighlighted ? Color.travelPrimary.opacity(0.24) : .black.opacity(0.16))
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(.white.opacity(isHighlighted ? 0.7 : 0.52), lineWidth: 1)
                )
        )
    }
}

private struct ManualPlanPlaceCard: View {
    let place: ManualPlanPlace
    let isSelected: Bool
    var onToggleSelection: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.travelPrimary.opacity(0.9), Color.green.opacity(0.65)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                if let imageURL = place.imageURL {
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
            }
            .frame(height: 140)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(alignment: .topLeading) {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                    Text(String(format: "%.1f", place.rating))
                        .font(.caption2.weight(.semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(.black.opacity(0.3), in: Capsule())
                .padding(8)
            }
            .overlay(alignment: .topTrailing) {
                DestinationWishlistButton(
                    source: .manualPlannerPlaces,
                    placeName: place.name,
                    district: place.district,
                    imageURL: place.imageURL
                )
                .padding(8)
            }

            Text(place.name)
                .font(.headline)
                .foregroundStyle(Color.travelTitle)

            HStack(spacing: 10) {
                Label(place.district, systemImage: "mappin.and.ellipse")
                Label("\(String(format: "%.4f", place.latitude)), \(String(format: "%.4f", place.longitude))", systemImage: "location")
            }
            .font(.caption)
            .foregroundStyle(Color.travelBody)

            Text(place.description)
                .font(.subheadline)
                .foregroundStyle(Color.travelBody)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                onToggleSelection()
            } label: {
                Text(isSelected ? "Selected" : "Select Destination")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isSelected ? Color.white : Color.travelPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(isSelected ? Color.travelPrimary : Color.travelPrimary.opacity(0.14))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.9))
        )
    }
}

#Preview {
    ManualTripPlannerScreen()
}
