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

	init(
		id: String,
		userId: String,
		sourceType: String,
		title: String,
		subtitle: String,
		status: String,
		totalStops: Int,
		visitedStops: Int,
		progress: Double,
		completedAt: String?,
		createdAt: String?,
		updatedAt: String?,
		stops: [OngoingTripStopRecord] = []
	) {
		self.id = id
		self.userId = userId
		self.sourceType = sourceType
		self.title = title
		self.subtitle = subtitle
		self.status = status
		self.totalStops = totalStops
		self.visitedStops = visitedStops
		self.progress = progress
		self.completedAt = completedAt
		self.createdAt = createdAt
		self.updatedAt = updatedAt
		self.stops = stops
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		self.id = try container.decode(String.self, forKey: .id)
		self.userId = try container.decodeIfPresent(String.self, forKey: .userId) ?? ""
		self.sourceType = try container.decodeIfPresent(String.self, forKey: .sourceType) ?? "manual_planner"
		self.title = try container.decodeIfPresent(String.self, forKey: .title) ?? "Untitled trip"
		self.subtitle = try container.decodeIfPresent(String.self, forKey: .subtitle) ?? ""
		self.status = try container.decodeIfPresent(String.self, forKey: .status) ?? "active"
		self.totalStops = try container.decodeIfPresent(Int.self, forKey: .totalStops) ?? 0
		self.visitedStops = try container.decodeIfPresent(Int.self, forKey: .visitedStops) ?? 0
		self.progress = try container.decodeIfPresent(Double.self, forKey: .progress) ?? 0
		self.completedAt = try container.decodeIfPresent(String.self, forKey: .completedAt)
		self.createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
		self.updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
		self.stops = []
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

	init(
		id: String,
		tripId: String,
		dayNumber: Int,
		sortOrder: Int,
		title: String,
		subtitle: String,
		description: String,
		latitude: Double,
		longitude: Double,
		imageNameString: String?,
		imageURLString: String?,
		plannedDateISO: String?,
		isVisited: Bool,
		visitedAt: String?
	) {
		self.id = id
		self.tripId = tripId
		self.dayNumber = dayNumber
		self.sortOrder = sortOrder
		self.title = title
		self.subtitle = subtitle
		self.description = description
		self.latitude = latitude
		self.longitude = longitude
		self.imageNameString = imageNameString
		self.imageURLString = imageURLString
		self.plannedDateISO = plannedDateISO
		self.isVisited = isVisited
		self.visitedAt = visitedAt
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		self.id = try container.decode(String.self, forKey: .id)
		self.tripId = try container.decodeIfPresent(String.self, forKey: .tripId) ?? ""
		self.dayNumber = try container.decodeIfPresent(Int.self, forKey: .dayNumber) ?? 1
		self.sortOrder = try container.decodeIfPresent(Int.self, forKey: .sortOrder) ?? 0
		self.title = try container.decodeIfPresent(String.self, forKey: .title) ?? "Stop"
		self.subtitle = try container.decodeIfPresent(String.self, forKey: .subtitle) ?? ""
		self.description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
		self.latitude = try container.decodeIfPresent(Double.self, forKey: .latitude) ?? 0
		self.longitude = try container.decodeIfPresent(Double.self, forKey: .longitude) ?? 0
		self.imageNameString = try container.decodeIfPresent(String.self, forKey: .imageNameString)
		self.imageURLString = try container.decodeIfPresent(String.self, forKey: .imageURLString)
		self.plannedDateISO = try container.decodeIfPresent(String.self, forKey: .plannedDateISO)
		self.isVisited = try container.decodeIfPresent(Bool.self, forKey: .isVisited) ?? false
		self.visitedAt = try container.decodeIfPresent(String.self, forKey: .visitedAt)
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
