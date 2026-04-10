import Foundation

struct WeatherSnapshot: Equatable {
    let cityName: String
    let temperatureCelsius: Int
    let isRainy: Bool

    var title: String {
        isRainy ? "Rainy" : "Sunny"
    }

    var description: String {
        isRainy ? "Take an umbrella" : "Perfect for hiking"
    }

    var backgroundImageName: String {
        isRainy ? "Rain" : "Sunny"
    }
}
