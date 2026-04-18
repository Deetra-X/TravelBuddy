import Foundation

enum WeatherConditionKind: Equatable {
    case sunny
    case cloudy
    case rainy
    case stormy
    case foggy
    case snowy
    case windy
    case unknown
}

struct WeatherForecastDay: Identifiable, Equatable {
    let date: Date
    let highTemperatureCelsius: Int
    let lowTemperatureCelsius: Int
    let condition: WeatherConditionKind

    var id: Date { date }

    var title: String {
        switch condition {
        case .sunny:
            return "Sunny"
        case .cloudy:
            return "Cloudy"
        case .rainy:
            return "Rainy"
        case .stormy:
            return "Stormy"
        case .foggy:
            return "Foggy"
        case .snowy:
            return "Snowy"
        case .windy:
            return "Windy"
        case .unknown:
            return "Mixed"
        }
    }

    var description: String {
        switch condition {
        case .sunny:
            return "Great for outdoor plans"
        case .cloudy:
            return "Comfortable and mild"
        case .rainy:
            return "Expect showers"
        case .stormy:
            return "Storms possible"
        case .foggy:
            return "Reduced visibility"
        case .snowy:
            return "Cold and snowy"
        case .windy:
            return "Windy conditions"
        case .unknown:
            return "Weather may vary"
        }
    }

    var symbolName: String {
        switch condition {
        case .sunny:
            return "sun.max.fill"
        case .cloudy:
            return "cloud.fill"
        case .rainy:
            return "cloud.rain.fill"
        case .stormy:
            return "cloud.bolt.rain.fill"
        case .foggy:
            return "cloud.fog.fill"
        case .snowy:
            return "snowflake"
        case .windy:
            return "wind"
        case .unknown:
            return "cloud.sun.fill"
        }
    }
}

struct WeatherSnapshot: Equatable {
    let cityName: String
    let temperatureCelsius: Int
    let condition: WeatherConditionKind
    let fetchedAt: Date

    init(
        cityName: String,
        temperatureCelsius: Int,
        condition: WeatherConditionKind,
        fetchedAt: Date = Date()
    ) {
        self.cityName = cityName
        self.temperatureCelsius = temperatureCelsius
        self.condition = condition
        self.fetchedAt = fetchedAt
    }

    var isRainy: Bool {
        condition == .rainy || condition == .stormy
    }

    var title: String {
        switch condition {
        case .sunny:
            return "Sunny"
        case .cloudy:
            return "Cloudy"
        case .rainy:
            return "Rainy"
        case .stormy:
            return "Stormy"
        case .foggy:
            return "Foggy"
        case .snowy:
            return "Snowy"
        case .windy:
            return "Windy"
        case .unknown:
            return "Clear"
        }
    }

    var description: String {
        switch condition {
        case .sunny:
            return "Great weather for exploring"
        case .cloudy:
            return "Comfortable for sightseeing"
        case .rainy:
            return "Take an umbrella"
        case .stormy:
            return "Heavy rain likely, plan indoor stops"
        case .foggy:
            return "Low visibility in some areas"
        case .snowy:
            return "Cold and snowy conditions"
        case .windy:
            return "Breezy weather outside"
        case .unknown:
            return "Weather is updating"
        }
    }

    var backgroundImageName: String {
        switch condition {
        case .rainy, .stormy:
            return "Rain"
        default:
            return "Sunny"
        }
    }

    var symbolName: String {
        switch condition {
        case .sunny:
            return "sun.max.fill"
        case .cloudy:
            return "cloud.fill"
        case .rainy:
            return "cloud.rain.fill"
        case .stormy:
            return "cloud.bolt.rain.fill"
        case .foggy:
            return "cloud.fog.fill"
        case .snowy:
            return "snowflake"
        case .windy:
            return "wind"
        case .unknown:
            return "cloud.sun.fill"
        }
    }
}

struct WeatherBundle: Equatable {
    let current: WeatherSnapshot
    let forecast: [WeatherForecastDay]
}
