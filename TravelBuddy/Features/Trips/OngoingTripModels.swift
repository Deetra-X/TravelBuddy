import Foundation
import CoreLocation

struct PlannedTripStopDraft: Codable, Hashable {
	let dayNumber: Int
	let sortOrder: Int
	let title: String
	let subtitle: String
	let description: String
	let latitude: Double
	let longitude: Double
	let imageName: String?
	let imageURLString: String?
	let plannedDateISO: String?
}

struct OngoingTripRecord: Codable, Identifiable, Hashable {
	let id: String
	let userId: String
	let sourceType: String
	let title: String
	let subtitle: String
	let status: String
	var totalStops: Int
	var visitedStops: Int
	var progress: Double
	let completedAt: String?
	let createdAt: String?
	let updatedAt: String?
	var stops: [OngoingTripStopRecord] = []

	enum CodingKeys: String, CodingKey {
		case id
		case userId = "user_id"
		case sourceType = "source_type"
		case title
		case subtitle
		case status
		case totalStops = "total_stops"
		case visitedStops = "visited_stops"
		case progress
		case completedAt = "completed_at"
		case createdAt = "created_at"
		case updatedAt = "updated_at"
	}

	var isCompleted: Bool {
		status.lowercased() == "completed"
	}

	var isActive: Bool {
		status.lowercased() == "active"
	}

	var resolvedVisitedStops: Int {
		if stops.isEmpty { return visitedStops }
		return stops.filter(\.isVisited).count
	}

	var resolvedTotalStops: Int {
		if stops.isEmpty { return totalStops }
		return stops.count
	}

	var resolvedProgress: Double {
		let total = resolvedTotalStops
		guard total > 0 else { return 0 }
		return Double(resolvedVisitedStops) / Double(total)
	}

	var displayProgressText: String {
		"\(resolvedVisitedStops) of \(resolvedTotalStops) stops visited"
	}

	var dateRangeText: String {
		let dates = stops.compactMap { $0.plannedDateISO }.sorted()
		guard let first = dates.first else { return subtitle }
		guard let last = dates.last, last != first else { return first }
		return "\(first) → \(last)"
	}
}

struct OngoingTripStopRecord: Codable, Identifiable, Hashable {
	let id: String
	let tripId: String
	let dayNumber: Int
	let sortOrder: Int
	let title: String
	let subtitle: String
	let description: String
	let latitude: Double
	let longitude: Double
	let imageNameString: String?
	let imageURLString: String?
	let plannedDateISO: String?
	var isVisited: Bool
	let visitedAt: String?

	enum CodingKeys: String, CodingKey {
		case id
		case tripId = "trip_id"
		case dayNumber = "day_number"
		case sortOrder = "sort_order"
		case title
		case subtitle
		case description
		case latitude
		case longitude
		case imageNameString = "image_name"
		case imageURLString = "image_url"
		case plannedDateISO = "planned_date"
		case isVisited = "is_visited"
		case visitedAt = "visited_at"
	}

	var coordinate: CLLocationCoordinate2D {
		CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
	}

	var imageURL: URL? {
		imageURLString.flatMap(URL.init(string:))
	}

	var imageName: String? {
		imageNameString
	}
}
