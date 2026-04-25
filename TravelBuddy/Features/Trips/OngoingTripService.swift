import Foundation

protocol OngoingTripServiceProtocol {
    func fetchTrips(session: AuthSession) async throws -> [OngoingTripRecord]
    func saveTrip(session: AuthSession, sourceType: String, title: String, subtitle: String, stops: [PlannedTripStopDraft]) async throws
    func markStopVisited(session: AuthSession, tripId: String, stopId: String, isVisited: Bool) async throws
    func markTripCompleted(session: AuthSession, tripId: String) async throws
    func deleteTrip(session: AuthSession, tripId: String) async throws
}

final class OngoingTripService: OngoingTripServiceProtocol {
    enum OngoingTripError: LocalizedError {
        case missingConfiguration
        case invalidResponse

        var errorDescription: String? {
            switch self {
            case .missingConfiguration:
                return "Supabase is not configured."
            case .invalidResponse:
                return "Failed to process ongoing trip response."
            }
        }
    }

    func fetchTrips(session: AuthSession) async throws -> [OngoingTripRecord] {
        guard AuthEndpoints.isConfigured, let baseURL = AuthEndpoints.baseURL else {
            throw OngoingTripError.missingConfiguration
        }

        guard var components = URLComponents(url: baseURL.appending(path: "/rest/v1/ongoing_trips"), resolvingAgainstBaseURL: false) else {
            throw URLError(.badURL)
        }

        components.queryItems = [
            URLQueryItem(name: "select", value: "id,user_id,source_type,title,subtitle,status,total_stops,visited_stops,progress,completed_at,created_at,updated_at"),
            URLQueryItem(name: "user_id", value: "eq.\(session.userId)"),
            URLQueryItem(name: "order", value: "updated_at.desc")
        ]

        guard let strictURL = components.url else { throw URLError(.badURL) }

        let fetchedTrips: [OngoingTripRecord]
        do {
            fetchedTrips = try await executeGet(url: strictURL, accessToken: session.accessToken)
        } catch {
            guard var fallbackComponents = URLComponents(url: baseURL.appending(path: "/rest/v1/ongoing_trips"), resolvingAgainstBaseURL: false) else {
                throw URLError(.badURL)
            }

            fallbackComponents.queryItems = [
                URLQueryItem(name: "select", value: "*"),
                URLQueryItem(name: "user_id", value: "eq.\(session.userId)"),
                URLQueryItem(name: "order", value: "updated_at.desc")
            ]

            guard let fallbackURL = fallbackComponents.url else { throw URLError(.badURL) }
            fetchedTrips = try await executeGet(url: fallbackURL, accessToken: session.accessToken)
        }

        var trips = fetchedTrips

        for index in trips.indices {
            do {
                trips[index].stops = try await fetchStops(session: session, tripId: trips[index].id)
            } catch {
                trips[index].stops = []
            }
        }

        return trips
    }

    func saveTrip(session: AuthSession, sourceType: String, title: String, subtitle: String, stops: [PlannedTripStopDraft]) async throws {
        guard AuthEndpoints.isConfigured, let baseURL = AuthEndpoints.baseURL else {
            throw OngoingTripError.missingConfiguration
        }

        let totalStops = stops.count
        let payload = [TripInsertPayload(
            userId: session.userId,
            sourceType: sourceType,
            title: title,
            subtitle: subtitle,
            status: "active",
            totalStops: totalStops,
            visitedStops: 0,
            progress: 0.0
        )]

        let tripURL = baseURL.appending(path: "/rest/v1/ongoing_trips")
        var tripRequest = makeRequest(url: tripURL, method: "POST", accessToken: session.accessToken)
        tripRequest.setValue("return=representation", forHTTPHeaderField: "Prefer")
        tripRequest.httpBody = try JSONEncoder().encode(payload)

        let (tripData, tripResponse) = try await URLSession.shared.data(for: tripRequest)
        guard let tripHTTP = tripResponse as? HTTPURLResponse,
              (200...299).contains(tripHTTP.statusCode) else {
            throw OngoingTripError.invalidResponse
        }

        guard let trip = try JSONDecoder().decode([OngoingTripRecord].self, from: tripData).first else {
            throw OngoingTripError.invalidResponse
        }

        if !stops.isEmpty {
            let stopPayload = stops.enumerated().map { index, stop in
                StopInsertPayload(
                    tripId: trip.id,
                    dayNumber: stop.dayNumber,
                    sortOrder: stop.sortOrder == 0 ? index : stop.sortOrder,
                    title: stop.title,
                    subtitle: stop.subtitle,
                    description: stop.description,
                    latitude: stop.latitude,
                    longitude: stop.longitude,
                    imageName: stop.imageName,
                    imageURLString: stop.imageURLString,
                    plannedDateISO: stop.plannedDateISO,
                    isVisited: false,
                    visitedAt: nil
                )
            }

            let stopURL = baseURL.appending(path: "/rest/v1/ongoing_trip_stops")
            var stopRequest = makeRequest(url: stopURL, method: "POST", accessToken: session.accessToken)
            stopRequest.setValue("return=representation", forHTTPHeaderField: "Prefer")
            stopRequest.httpBody = try JSONEncoder().encode(stopPayload)

            let (_, stopResponse) = try await URLSession.shared.data(for: stopRequest)
            guard let stopHTTP = stopResponse as? HTTPURLResponse,
                  (200...299).contains(stopHTTP.statusCode) else {
                throw OngoingTripError.invalidResponse
            }
        }
    }

    func markStopVisited(session: AuthSession, tripId: String, stopId: String, isVisited: Bool) async throws {
        guard AuthEndpoints.isConfigured, let baseURL = AuthEndpoints.baseURL else {
            throw OngoingTripError.missingConfiguration
        }

        let patch: [String: Any] = [
            "is_visited": isVisited,
            "visited_at": isVisited ? ISO8601DateFormatter().string(from: Date()) : NSNull()
        ]

        guard var stopComponents = URLComponents(url: baseURL.appending(path: "/rest/v1/ongoing_trip_stops"), resolvingAgainstBaseURL: false) else {
            throw URLError(.badURL)
        }
        stopComponents.queryItems = [URLQueryItem(name: "id", value: "eq.\(stopId)")]
        guard let stopURL = stopComponents.url else { throw URLError(.badURL) }

        var stopRequest = makeRequest(url: stopURL, method: "PATCH", accessToken: session.accessToken)
        stopRequest.httpBody = try JSONSerialization.data(withJSONObject: patch)

        let (_, stopResponse) = try await URLSession.shared.data(for: stopRequest)
        guard let stopHTTP = stopResponse as? HTTPURLResponse,
              (200...299).contains(stopHTTP.statusCode) else {
            throw OngoingTripError.invalidResponse
        }

        let stops = try await fetchStops(session: session, tripId: tripId)
        let total = stops.count
        let visited = stops.filter(\.isVisited).count
        let progress = total > 0 ? Double(visited) / Double(total) : 0

        let tripUpdate: [String: Any] = [
            "total_stops": total,
            "visited_stops": visited,
            "progress": progress,
            "updated_at": ISO8601DateFormatter().string(from: Date())
        ]

        guard var tripComponents = URLComponents(url: baseURL.appending(path: "/rest/v1/ongoing_trips"), resolvingAgainstBaseURL: false) else {
            throw URLError(.badURL)
        }
        tripComponents.queryItems = [URLQueryItem(name: "id", value: "eq.\(tripId)")]
        guard let tripURL = tripComponents.url else { throw URLError(.badURL) }

        var tripRequest = makeRequest(url: tripURL, method: "PATCH", accessToken: session.accessToken)
        tripRequest.httpBody = try JSONSerialization.data(withJSONObject: tripUpdate)

        let (_, tripResponse) = try await URLSession.shared.data(for: tripRequest)
        guard let tripHTTP = tripResponse as? HTTPURLResponse,
              (200...299).contains(tripHTTP.statusCode) else {
            throw OngoingTripError.invalidResponse
        }
    }

    func markTripCompleted(session: AuthSession, tripId: String) async throws {
        guard AuthEndpoints.isConfigured, let baseURL = AuthEndpoints.baseURL else {
            throw OngoingTripError.missingConfiguration
        }

        let completedAt = ISO8601DateFormatter().string(from: Date())
        let tripUpdate: [String: Any] = [
            "status": "completed",
            "completed_at": completedAt,
            "updated_at": completedAt
        ]

        guard var components = URLComponents(url: baseURL.appending(path: "/rest/v1/ongoing_trips"), resolvingAgainstBaseURL: false) else {
            throw URLError(.badURL)
        }
        components.queryItems = [URLQueryItem(name: "id", value: "eq.\(tripId)")]
        guard let url = components.url else { throw URLError(.badURL) }

        var request = makeRequest(url: url, method: "PATCH", accessToken: session.accessToken)
        request.httpBody = try JSONSerialization.data(withJSONObject: tripUpdate)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw OngoingTripError.invalidResponse
        }
    }

    func deleteTrip(session: AuthSession, tripId: String) async throws {
        guard AuthEndpoints.isConfigured, let baseURL = AuthEndpoints.baseURL else {
            throw OngoingTripError.missingConfiguration
        }

        guard var components = URLComponents(url: baseURL.appending(path: "/rest/v1/ongoing_trips"), resolvingAgainstBaseURL: false) else {
            throw URLError(.badURL)
        }

        components.queryItems = [
            URLQueryItem(name: "id", value: "eq.\(tripId)"),
            URLQueryItem(name: "user_id", value: "eq.\(session.userId)")
        ]

        guard let url = components.url else { throw URLError(.badURL) }

        var request = makeRequest(url: url, method: "DELETE", accessToken: session.accessToken)
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw OngoingTripError.invalidResponse
        }
    }

    private func fetchStops(session: AuthSession, tripId: String) async throws -> [OngoingTripStopRecord] {
        guard AuthEndpoints.isConfigured, let baseURL = AuthEndpoints.baseURL else {
            throw OngoingTripError.missingConfiguration
        }

        guard var components = URLComponents(url: baseURL.appending(path: "/rest/v1/ongoing_trip_stops"), resolvingAgainstBaseURL: false) else {
            throw URLError(.badURL)
        }

        components.queryItems = [
            URLQueryItem(name: "select", value: "id,trip_id,day_number,sort_order,title,subtitle,description,latitude,longitude,image_name,image_url,planned_date,is_visited,visited_at"),
            URLQueryItem(name: "trip_id", value: "eq.\(tripId)"),
            URLQueryItem(name: "order", value: "day_number.asc,sort_order.asc")
        ]

        guard let url = components.url else { throw URLError(.badURL) }
        return try await executeGet(url: url, accessToken: session.accessToken)
    }

    private func executeGet<T: Decodable>(url: URL, accessToken: String) async throws -> T {
        let request = makeRequest(url: url, method: "GET", accessToken: accessToken)
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw OngoingTripError.invalidResponse
        }

        return try JSONDecoder().decode(T.self, from: data)
    }

    private func makeRequest(url: URL, method: String, accessToken: String) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        return request
    }
}

private struct TripInsertPayload: Encodable {
    let userId: String
    let sourceType: String
    let title: String
    let subtitle: String
    let status: String
    let totalStops: Int
    let visitedStops: Int
    let progress: Double

    private enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case sourceType = "source_type"
        case title
        case subtitle
        case status
        case totalStops = "total_stops"
        case visitedStops = "visited_stops"
        case progress
    }
}

private struct StopInsertPayload: Encodable {
    let tripId: String
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
    let isVisited: Bool
    let visitedAt: String?

    private enum CodingKeys: String, CodingKey {
        case tripId = "trip_id"
        case dayNumber = "day_number"
        case sortOrder = "sort_order"
        case title
        case subtitle
        case description
        case latitude
        case longitude
        case imageName = "image_name"
        case imageURLString = "image_url"
        case plannedDateISO = "planned_date"
        case isVisited = "is_visited"
        case visitedAt = "visited_at"
    }
}
