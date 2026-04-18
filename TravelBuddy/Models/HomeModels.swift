import Foundation
import CoreLocation

enum WishlistPlaceSource: String, Codable, Hashable {
    case places
    case manualPlannerPlaces = "manual_planner_places"
}

struct PlaceCardItem: Identifiable {
    let id: String
    let wishlistPlaceId: String?
    let wishlistSource: WishlistPlaceSource
    let name: String
    let description: String
    let subtitle: String
    let rating: Double
    let coordinate: CLLocationCoordinate2D
    let accentHex: String
    let imageURL: URL?

    init(
        id: String = UUID().uuidString,
        wishlistPlaceId: String? = nil,
        wishlistSource: WishlistPlaceSource = .places,
        name: String,
        description: String,
        subtitle: String,
        rating: Double,
        coordinate: CLLocationCoordinate2D,
        accentHex: String,
        imageURL: URL? = nil
    ) {
        self.id = id
        self.wishlistPlaceId = wishlistPlaceId
        self.wishlistSource = wishlistSource
        self.name = name
        self.description = description
        self.subtitle = subtitle
        self.rating = rating
        self.coordinate = coordinate
        self.accentHex = accentHex
        self.imageURL = imageURL
    }
}

struct CloudPlaceRecord: Decodable {
    let id: String
    let district: String
    let name: String
    let description: String
    let rating: Double
    let latitude: Double
    let longitude: Double
    let imageURLString: String?

    enum CodingKeys: String, CodingKey {
        case id
        case district
        case name
        case description
        case rating
        case latitude
        case longitude
        case imageURLString = "image_url"
    }

    func toPlaceCardItem() -> PlaceCardItem {
        PlaceCardItem(
            id: id,
            wishlistPlaceId: id,
            wishlistSource: .places,
            name: name,
            description: description,
            subtitle: district,
            rating: rating,
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            accentHex: "0D47A1",
            imageURL: imageURLString.flatMap(URL.init(string:))
        )
    }
}

struct QuickPlanItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let duration: String
    let description: String
    let itinerary: [ItineraryStop]
    let category: String
}

struct ItineraryStop: Identifiable {
    let id = UUID()
    let day: Int
    let title: String
    let description: String
    let coordinate: CLLocationCoordinate2D
    let icon: String
    let imageURLString: String?
}

struct ExperienceItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let accentHex: String
    let imageName: String?
    let imageURL: URL?
    let matchedPlaces: [PlaceCardItem]

    init(title: String, subtitle: String, icon: String, accentHex: String, imageName: String? = nil, imageURLString: String? = nil, matchedPlaces: [PlaceCardItem] = []) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.accentHex = accentHex
        self.imageName = imageName
        self.imageURL = imageURLString.flatMap(URL.init(string:))
        self.matchedPlaces = matchedPlaces
    }
}

struct OngoingTripItem {
    let title: String
    let progressText: String
    let progress: Double
}

enum HomeMockData {
    static let explorePlaces: [PlaceCardItem] = [
        PlaceCardItem(
            wishlistSource: .places,
            name: "Nine Arch Bridge",
            description: "Iconic railway bridge surrounded by greenery.",
            subtitle: "Ella",
            rating: 4.9,
            coordinate: CLLocationCoordinate2D(latitude: 6.8756, longitude: 81.0607),
            accentHex: "1B5E20"
        ),
        PlaceCardItem(
            wishlistSource: .places,
            name: "Alpha Mosque",
            description: "Historic urban landmark in Colombo.",
            subtitle: "Colombo",
            rating: 4.7,
            coordinate: CLLocationCoordinate2D(latitude: 6.9344, longitude: 79.8528),
            accentHex: "7B3F00"
        ),
        PlaceCardItem(
            wishlistSource: .places,
            name: "Olu Ella",
            description: "Scenic waterfall destination in hill country.",
            subtitle: "Badulla",
            rating: 4.8,
            coordinate: CLLocationCoordinate2D(latitude: 6.9934, longitude: 81.0550),
            accentHex: "0D47A1"
        ),
        PlaceCardItem(
            wishlistSource: .places,
            name: "Kothmale",
            description: "Popular scenic area with mountain views.",
            subtitle: "Nuwara Eliya",
            rating: 4.6,
            coordinate: CLLocationCoordinate2D(latitude: 7.0258, longitude: 80.6002),
            accentHex: "4E342E"
        )
    ]

    static let quickPlans: [QuickPlanItem] = [
        QuickPlanItem(title: "1 Day in Colombo", subtitle: "Architecture, markets & food", icon: "building.2.fill", duration: "1 Day", description: "Explore Colombo's vibrant culture.", itinerary: [], category: "city"),
        QuickPlanItem(title: "2 Day in Ella", subtitle: "Nine Arch Bridge, hiking trails", icon: "mountain.2.fill", duration: "2 Days", description: "Adventure in the mountains.", itinerary: [], category: "adventure"),
        QuickPlanItem(title: "1 Day in Kandy", subtitle: "Temple, city views & culture", icon: "tram.fill", duration: "1 Day", description: "Cultural experience in Kandy.", itinerary: [], category: "culture")
    ]

    static let experiences: [ExperienceItem] = [
        ExperienceItem(
            title: "Beach escapes",
            subtitle: "Sunny coast",
            icon: "sun.max.fill",
            accentHex: "006064",
            imageName: "ocean"
        ),
        ExperienceItem(
            title: "Hiking Adventures",
            subtitle: "Mountain trails",
            icon: "figure.hiking",
            accentHex: "1B5E20",
            imageName: "hikin_home"
        ),
        ExperienceItem(
            title: "Scenic Rides",
            subtitle: "Train journeys",
            icon: "train.side.front.car",
            accentHex: "4E342E",
            imageName: "train"
        ),
        ExperienceItem(
            title: "Culture Journeys",
            subtitle: "Temples & history",
            icon: "building.columns.fill",
            accentHex: "6A1B9A",
            imageName: "culture_home"
        )
    ]

    static let ongoingTrip = OngoingTripItem(
        title: "Hiking Ella Rock",
        progressText: "Day 3 of 5 • Ella",
        progress: 0.62
    )
}
