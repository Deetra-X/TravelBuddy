import Foundation
import CoreLocation

struct PlaceCardItem: Identifiable {
    let id = UUID()
    let name: String
    let subtitle: String
    let rating: Double
    let coordinate: CLLocationCoordinate2D
    let accentHex: String
}

struct QuickPlanItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
}

struct ExperienceItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let accentHex: String
}

struct OngoingTripItem {
    let title: String
    let progressText: String
    let progress: Double
}

enum HomeMockData {
    static let explorePlaces: [PlaceCardItem] = [
        PlaceCardItem(
            name: "Nine Arch Bridge",
            subtitle: "Ella",
            rating: 4.9,
            coordinate: CLLocationCoordinate2D(latitude: 6.8756, longitude: 81.0607),
            accentHex: "1B5E20"
        ),
        PlaceCardItem(
            name: "Alpha Mosque",
            subtitle: "Colombo",
            rating: 4.7,
            coordinate: CLLocationCoordinate2D(latitude: 6.9344, longitude: 79.8528),
            accentHex: "7B3F00"
        ),
        PlaceCardItem(
            name: "Olu Ella",
            subtitle: "Badulla",
            rating: 4.8,
            coordinate: CLLocationCoordinate2D(latitude: 6.9934, longitude: 81.0550),
            accentHex: "0D47A1"
        ),
        PlaceCardItem(
            name: "Kothmale",
            subtitle: "Nuwara Eliya",
            rating: 4.6,
            coordinate: CLLocationCoordinate2D(latitude: 7.0258, longitude: 80.6002),
            accentHex: "4E342E"
        )
    ]

    static let quickPlans: [QuickPlanItem] = [
        QuickPlanItem(title: "1 Day in Colombo", subtitle: "Architecture, markets & food", icon: "building.2.fill"),
        QuickPlanItem(title: "2 Day in Ella", subtitle: "Nine Arch Bridge, hiking trails", icon: "mountain.2.fill"),
        QuickPlanItem(title: "1 Day in Kandy", subtitle: "Temple, city views & culture", icon: "tram.fill")
    ]

    static let experiences: [ExperienceItem] = [
        ExperienceItem(title: "Beach escapes", subtitle: "Sunny coast", icon: "sun.max.fill", accentHex: "006064"),
        ExperienceItem(title: "Hiking Adventures", subtitle: "Mountain trails", icon: "figure.hiking", accentHex: "1B5E20"),
        ExperienceItem(title: "Scenic Rides", subtitle: "Train journeys", icon: "train.side.front.car", accentHex: "4E342E"),
        ExperienceItem(title: "Culture Journeys", subtitle: "Temples & history", icon: "building.columns.fill", accentHex: "6A1B9A")
    ]

    static let ongoingTrip = OngoingTripItem(
        title: "Hiking Ella Rock",
        progressText: "Day 3 of 5 • Ella",
        progress: 0.62
    )
}
