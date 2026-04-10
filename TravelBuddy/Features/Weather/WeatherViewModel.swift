import Foundation
import CoreLocation
import Combine

@MainActor
final class WeatherViewModel: ObservableObject {
    @Published private(set) var weather: WeatherSnapshot = WeatherSnapshot(
        cityName: "Colombo",
        temperatureCelsius: 34,
        isRainy: false
    )
    @Published private(set) var isLoading: Bool = false

    private let service: WeatherServiceProtocol
    private var lastRequestedLocation: CLLocation?

    init(service: WeatherServiceProtocol = WeatherService()) {
        self.service = service
    }

    func refreshIfNeeded(from location: CLLocation?) {
        guard let location else {
            setColomboFallbackWeather()
            return
        }

        if let lastRequestedLocation,
           location.distance(from: lastRequestedLocation) < 1000 {
            return
        }

        lastRequestedLocation = location
        Task {
            await refreshWeather(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        }
    }

    func refreshWeather(latitude: Double, longitude: Double) async {
        isLoading = true
        defer { isLoading = false }

        do {
            weather = try await service.fetchCurrentWeather(latitude: latitude, longitude: longitude)
        } catch {
            setColomboFallbackWeather()
        }
    }

    func setColomboFallbackWeather() {
        weather = WeatherSnapshot(
            cityName: "Colombo",
            temperatureCelsius: 34,
            isRainy: false
        )
    }
}
