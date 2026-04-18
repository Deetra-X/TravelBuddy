import Foundation
import CoreLocation
import Combine

@MainActor
final class NearbyPlacesViewModel: ObservableObject {
    @Published private(set) var allPlaces: [PlaceCardItem] = []
    @Published private(set) var nearbyPlaces: [PlaceCardItem] = []
    @Published private(set) var isLoading: Bool = false

    private let service: NearbyPlacesServiceProtocol
    private var hasLoaded = false

    init(service: NearbyPlacesServiceProtocol = NearbyPlacesService()) {
        self.service = service
    }

    func loadPlacesIfNeeded(currentLocation: CLLocation?, districtFilter: String? = nil) {
        guard !hasLoaded else {
            updateNearbyPlaces(currentLocation: currentLocation, districtFilter: districtFilter)
            return
        }

        hasLoaded = true
        Task {
            await fetchPlaces(currentLocation: currentLocation, districtFilter: districtFilter)
        }
    }

    func updateNearbyPlaces(currentLocation: CLLocation?, districtFilter: String? = nil) {
        guard !allPlaces.isEmpty else {
            nearbyPlaces = []
            return
        }

        let sourcePlaces: [PlaceCardItem]
        if let districtFilter, !districtFilter.isEmpty {
            sourcePlaces = allPlaces.filter { $0.subtitle.caseInsensitiveCompare(districtFilter) == .orderedSame }
        } else {
            sourcePlaces = allPlaces
        }

        if let currentLocation {
            nearbyPlaces = sourcePlaces
                .sorted { left, right in
                    let leftLocation = CLLocation(latitude: left.coordinate.latitude, longitude: left.coordinate.longitude)
                    let rightLocation = CLLocation(latitude: right.coordinate.latitude, longitude: right.coordinate.longitude)
                    return currentLocation.distance(from: leftLocation) < currentLocation.distance(from: rightLocation)
                }
                .prefix(4)
                .map { $0 }
        } else {
            nearbyPlaces = Array(sourcePlaces.prefix(4))
        }
    }

    private func fetchPlaces(currentLocation: CLLocation?, districtFilter: String?) async {
        isLoading = true
        defer { isLoading = false }

        do {
            allPlaces = try await service.fetchPlaces()
            updateNearbyPlaces(currentLocation: currentLocation, districtFilter: districtFilter)
        } catch {
            allPlaces = []
            updateNearbyPlaces(currentLocation: currentLocation, districtFilter: districtFilter)
        }
    }
}
