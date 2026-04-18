import Foundation
import CoreLocation

protocol WeatherServiceProtocol {
    func fetchCurrentWeather(latitude: Double, longitude: Double) async throws -> WeatherSnapshot
    func fetchThreeDayForecast(latitude: Double, longitude: Double) async throws -> [WeatherForecastDay]
}

final class WeatherService: WeatherServiceProtocol {
    func fetchCurrentWeather(latitude: Double, longitude: Double) async throws -> WeatherSnapshot {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let payload = try await fetchOpenMeteoWeather(latitude: latitude, longitude: longitude)
        let temperature = Int(payload.currentWeather.temperature.rounded())
        let condition = Self.classifyCondition(code: payload.currentWeather.weathercode)

        let geocoder = CLGeocoder()
        let placemarks = try? await geocoder.reverseGeocodeLocation(location)
        let cityName = resolvedCityName(from: placemarks?.first)
            ?? String(format: "%.3f, %.3f", latitude, longitude)

        return WeatherSnapshot(
            cityName: cityName,
            temperatureCelsius: temperature,
            condition: condition,
            fetchedAt: Date()
        )
    }

    func fetchThreeDayForecast(latitude: Double, longitude: Double) async throws -> [WeatherForecastDay] {
        let payload = try await fetchOpenMeteoWeather(latitude: latitude, longitude: longitude)
        guard let daily = payload.daily else { return [] }

        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"

        return zip4(daily.time, daily.temperature2mMax, daily.temperature2mMin, daily.weathercode)
            .prefix(3)
            .compactMap { entry in
                guard let date = formatter.date(from: entry.0) else { return nil }
                return WeatherForecastDay(
                    date: date,
                    highTemperatureCelsius: Int(entry.1.rounded()),
                    lowTemperatureCelsius: Int(entry.2.rounded()),
                    condition: Self.classifyCondition(code: entry.3)
                )
            }
    }

    private func fetchOpenMeteoWeather(latitude: Double, longitude: Double) async throws -> OpenMeteoResponse {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")
        components?.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "current_weather", value: "true"),
            URLQueryItem(name: "daily", value: "temperature_2m_max,temperature_2m_min,weathercode"),
            URLQueryItem(name: "timezone", value: "auto")
        ]

        guard let url = components?.url else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
    }

    private func resolvedCityName(from placemark: CLPlacemark?) -> String? {
        placemark?.locality
        ?? placemark?.subAdministrativeArea
        ?? placemark?.administrativeArea
        ?? placemark?.country
    }

    private static func classifyCondition(code: Int) -> WeatherConditionKind {
        switch code {
        case 0:
            return .sunny
        case 1, 2:
            return .sunny
        case 3:
            return .cloudy
        case 45, 48:
            return .foggy
        case 51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82:
            return .rainy
        case 71, 73, 75, 77, 85, 86:
            return .snowy
        case 95, 96, 99:
            return .stormy
        default:
            return .unknown
        }
    }

    private func zip4<A, B, C, D>(_ a: [A], _ b: [B], _ c: [C], _ d: [D]) -> [(A, B, C, D)] {
        let count = min(a.count, b.count, c.count, d.count)
        guard count > 0 else { return [] }

        return (0..<count).map { index in
            (a[index], b[index], c[index], d[index])
        }
    }
}

private struct OpenMeteoResponse: Decodable {
    let currentWeather: CurrentWeather
    let daily: Daily?

    enum CodingKeys: String, CodingKey {
        case currentWeather = "current_weather"
        case daily
    }

    struct CurrentWeather: Decodable {
        let temperature: Double
        let weathercode: Int
    }

    struct Daily: Decodable {
        let time: [String]
        let temperature2mMax: [Double]
        let temperature2mMin: [Double]
        let weathercode: [Int]

        enum CodingKeys: String, CodingKey {
            case time
            case temperature2mMax = "temperature_2m_max"
            case temperature2mMin = "temperature_2m_min"
            case weathercode
        }
    }
}
