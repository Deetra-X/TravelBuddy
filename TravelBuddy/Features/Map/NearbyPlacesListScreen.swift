import SwiftUI
import CoreLocation

struct NearbyPlacesListScreen: View {
    @EnvironmentObject private var sessionManager: SessionManager

    let items: [PlaceCardItem]
    let currentLocation: CLLocation?
    let onClose: () -> Void

    @State private var searchText: String = ""
    @State private var selectedDistrict: String = "All"
    @State private var selectedPlace: PlaceCardItem?
    @State private var showPlaceDetails: Bool = false

    var body: some View {
        NavigationStack {
            List(filteredItems) { item in
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color(hex: item.accentHex).opacity(0.18))
                        .frame(width: 42, height: 42)
                        .overlay {
                            Image(systemName: "location.fill")
                                .foregroundStyle(Color(hex: item.accentHex))
                        }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.name)
                            .font(.headline)
                            .foregroundStyle(Color.travelTitle)

                        Text(item.description)
                            .font(.caption)
                            .foregroundStyle(Color.travelBody)
                            .lineLimit(2)

                        Text("\(distanceText(for: item.coordinate)) • \(item.subtitle)")
                            .font(.caption2)
                            .foregroundStyle(Color.travelBody)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 8) {
                        DestinationWishlistButton(
                            directPlaceId: item.wishlistPlaceId,
                            source: item.wishlistSource,
                            placeName: item.name,
                            district: item.subtitle,
                            imageURL: item.imageURL
                        )

                        Text(String(format: "%.1f", item.rating))
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.black.opacity(0.07), in: Capsule())
                    }
                }
                .padding(.vertical, 4)
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedPlace = item
                    showPlaceDetails = true
                }
            }
            .listStyle(.plain)
            .navigationTitle("Places around you")
            .searchable(text: $searchText, prompt: "Search destination")
            .navigationDestination(isPresented: $showPlaceDetails) {
                if let item = selectedPlace {
                    PlaceDetailsScreen(
                        placeName: item.name,
                        district: item.subtitle,
                        fallbackDescription: item.description,
                        fallbackImageURL: item.imageURL,
                        fallbackRating: item.rating,
                        fallbackLatitude: item.coordinate.latitude,
                        fallbackLongitude: item.coordinate.longitude,
                        currentLocation: currentLocation
                    )
                    .environmentObject(sessionManager)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Back") {
                        onClose()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("All") { selectedDistrict = "All" }
                        ForEach(districtOptions, id: \.self) { district in
                            Button(district) { selectedDistrict = district }
                        }
                    } label: {
                        Label(selectedDistrict, systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
            }
        }
    }

    private var districtOptions: [String] {
        let districts = items.map(\ .subtitle)
        return Array(Set(districts)).sorted()
    }

    private var filteredItems: [PlaceCardItem] {
        items.filter { item in
            let districtMatches = selectedDistrict == "All"
                || item.subtitle.caseInsensitiveCompare(selectedDistrict) == .orderedSame

            let searchMatches = searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || item.name.localizedCaseInsensitiveContains(searchText)
                || item.description.localizedCaseInsensitiveContains(searchText)

            return districtMatches && searchMatches
        }
    }

    private func distanceText(for coordinate: CLLocationCoordinate2D) -> String {
        guard let currentLocation else {
            return "-- km"
        }

        let placeLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let distanceInKm = currentLocation.distance(from: placeLocation) / 1000
        return String(format: "%.1f km", distanceInKm)
    }
}
