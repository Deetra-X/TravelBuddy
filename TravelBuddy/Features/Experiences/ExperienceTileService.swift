import Foundation

struct ExperienceTileRule: Decodable, Identifiable, Hashable {
    let id: String
    let tileKey: String
    let title: String
    let subtitle: String
    let icon: String
    let accentHex: String
    let imageName: String?
    let nameKeywords: [String]
    let descriptionKeywords: [String]
    let districtKeywords: [String]
    let sortOrder: Int

    private enum CodingKeys: String, CodingKey {
        case id
        case tileKey = "tile_key"
        case title
        case subtitle
        case icon
        case accentHex = "accent_hex"
        case imageName = "image_name"
        case nameKeywords = "name_keywords"
        case descriptionKeywords = "description_keywords"
        case districtKeywords = "district_keywords"
        case sortOrder = "sort_order"
    }
}

protocol ExperienceTileServiceProtocol {
    func fetchTileRules() async throws -> [ExperienceTileRule]
}

final class ExperienceTileService: ExperienceTileServiceProtocol {
    enum ExperienceTileError: LocalizedError {
        case missingConfiguration
        case invalidResponse

        var errorDescription: String? {
            switch self {
            case .missingConfiguration:
                return "Supabase is not configured."
            case .invalidResponse:
                return "Failed to load experience tiles."
            }
        }
    }

    func fetchTileRules() async throws -> [ExperienceTileRule] {
        guard AuthEndpoints.isConfigured,
              let baseURL = AuthEndpoints.baseURL else {
            throw ExperienceTileError.missingConfiguration
        }

        guard var components = URLComponents(url: baseURL.appending(path: "/rest/v1/experience_tiles"), resolvingAgainstBaseURL: false) else {
            throw URLError(.badURL)
        }

        components.queryItems = [
            URLQueryItem(name: "select", value: "id,tile_key,title,subtitle,icon,accent_hex,image_name,name_keywords,description_keywords,district_keywords,sort_order"),
            URLQueryItem(name: "order", value: "sort_order.asc")
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
            throw ExperienceTileError.invalidResponse
        }

        return try JSONDecoder().decode([ExperienceTileRule].self, from: data)
    }
}
