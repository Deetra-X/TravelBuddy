import Foundation

protocol NearbyPlacesServiceProtocol {
    func fetchPlaces() async throws -> [PlaceCardItem]
}

final class NearbyPlacesService: NearbyPlacesServiceProtocol {
    enum NearbyPlacesError: LocalizedError {
        case missingConfiguration
        case invalidResponse

        var errorDescription: String? {
            switch self {
            case .missingConfiguration:
                return "Supabase is not configured."
            case .invalidResponse:
                return "Failed to load nearby places."
            }
        }
    }

    func fetchPlaces() async throws -> [PlaceCardItem] {
        guard AuthEndpoints.isConfigured,
              let baseURL = AuthEndpoints.baseURL else {
            throw NearbyPlacesError.missingConfiguration
        }

        guard var components = URLComponents(url: baseURL.appending(path: "/rest/v1/places"), resolvingAgainstBaseURL: false) else {
            throw URLError(.badURL)
        }

        components.queryItems = [
            URLQueryItem(name: "select", value: "id,district,name,description,rating,latitude,longitude,image_url"),
            URLQueryItem(name: "order", value: "rating.desc")
        ]

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NearbyPlacesError.invalidResponse
        }

        let decoded = try JSONDecoder().decode([CloudPlaceRecord].self, from: data)
        return decoded.map { $0.toPlaceCardItem() }
    }
}
