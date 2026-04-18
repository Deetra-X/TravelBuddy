import Foundation
import CoreLocation
import Combine

@MainActor
final class WeatherViewModel: ObservableObject {
    @Published private(set) var weather: WeatherSnapshot = WeatherSnapshot(
        cityName: "Colombo",
        temperatureCelsius: 34,
        condition: .sunny
    )
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var lastErrorMessage: String?

    private let service: WeatherServiceProtocol
    private var lastRequestedLocation: CLLocation?
    private var lastSuccessfulRefreshAt: Date?
    private let refreshDistanceMeters: CLLocationDistance = 1000
    private let refreshTTL: TimeInterval = 60 * 10

    init(service: WeatherServiceProtocol) {
        self.service = service
    }

    init() {
        self.service = WeatherService()
    }

    func refreshIfNeeded(from location: CLLocation?) {
        guard let location else {
            if lastSuccessfulRefreshAt == nil {
                setColomboFallbackWeather()
            }
            return
        }

        if isLoading {
            return
        }

        let hasMovedEnough: Bool
        if let lastRequestedLocation {
            hasMovedEnough = location.distance(from: lastRequestedLocation) >= refreshDistanceMeters
        } else {
            hasMovedEnough = true
        }

        let isStale = {
            guard let lastSuccessfulRefreshAt else { return true }
            return Date().timeIntervalSince(lastSuccessfulRefreshAt) >= refreshTTL
        }()

        if !hasMovedEnough && !isStale {
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
            lastSuccessfulRefreshAt = Date()
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = "Could not fetch live weather. Showing the latest available weather."

            if lastSuccessfulRefreshAt == nil {
                setColomboFallbackWeather()
            }
        }
    }

    func setColomboFallbackWeather() {
        weather = WeatherSnapshot(
            cityName: "Colombo",
            temperatureCelsius: 34,
            condition: .sunny,
            fetchedAt: Date()
        )
        lastSuccessfulRefreshAt = Date()
    }
}
