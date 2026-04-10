import Foundation
import CoreLocation
import WeatherKit

protocol WeatherServiceProtocol {
    func fetchCurrentWeather(latitude: Double, longitude: Double) async throws -> WeatherSnapshot
}

final class WeatherService: WeatherServiceProtocol {
    private let weatherKitService = WeatherKit.WeatherService()

    func fetchCurrentWeather(latitude: Double, longitude: Double) async throws -> WeatherSnapshot {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let weather = try await weatherKitService.weather(for: location)
        let temperature = Int(weather.currentWeather.temperature.converted(to: UnitTemperature.celsius).value.rounded())
        let isRainy = Self.isRainCondition(weather.currentWeather.condition)

        let geocoder = CLGeocoder()
        let placemarks = try? await geocoder.reverseGeocodeLocation(location)
        let cityName = placemarks?.first?.locality
            ?? placemarks?.first?.subAdministrativeArea
            ?? "your location"

        return WeatherSnapshot(
            cityName: cityName,
            temperatureCelsius: temperature,
            isRainy: isRainy
        )
    }

    private static func isRainCondition(_ condition: WeatherCondition) -> Bool {
        let value = String(describing: condition).lowercased()
        return value.contains("rain")
            || value.contains("drizzle")
            || value.contains("shower")
            || value.contains("thunder")
            || value.contains("storm")
    }
}
