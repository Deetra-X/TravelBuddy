import Foundation

struct SidebarUserDetails: Equatable {
    let userId: String
    let fullName: String
    let email: String
    let locationEnabled: Bool
    let pushNotificationsEnabled: Bool
    let language: String
}

protocol SidebarProfileServiceProtocol {
    func fetchUserDetails(session: AuthSession) async throws -> SidebarUserDetails
    func savePreferences(
        session: AuthSession,
        locationEnabled: Bool,
        pushNotificationsEnabled: Bool,
        language: String
    ) async throws
}

struct SidebarProfileService: SidebarProfileServiceProtocol {
    enum SidebarProfileError: LocalizedError {
        case missingConfiguration
        case invalidResponse

        var errorDescription: String? {
            switch self {
            case .missingConfiguration:
                return "Supabase is not configured."
            case .invalidResponse:
                return "Failed to process profile response."
            }
        }
    }

    func fetchUserDetails(session: AuthSession) async throws -> SidebarUserDetails {
        guard AuthEndpoints.isConfigured, let baseURL = AuthEndpoints.baseURL else {
            throw SidebarProfileError.missingConfiguration
        }

        let profileName = try await fetchProfileName(baseURL: baseURL, session: session)
        let preferences = try await fetchPreferences(baseURL: baseURL, session: session)

        let resolvedName = profileName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty ? session.userName : profileName

        return SidebarUserDetails(
            userId: session.userId,
            fullName: resolvedName,
            email: session.userEmail,
            locationEnabled: preferences?.locationEnabled ?? true,
            pushNotificationsEnabled: preferences?.pushNotificationsEnabled ?? false,
            language: preferences?.language ?? "English"
        )
    }

    func savePreferences(
        session: AuthSession,
        locationEnabled: Bool,
        pushNotificationsEnabled: Bool,
        language: String
    ) async throws {
        guard AuthEndpoints.isConfigured, let baseURL = AuthEndpoints.baseURL else {
            throw SidebarProfileError.missingConfiguration
        }

        let url = baseURL.appending(path: "/rest/v1/user_preferences")
        let payload = [
            PreferencesUpsertPayload(
                userId: session.userId,
                locationEnabled: locationEnabled,
                pushNotificationsEnabled: pushNotificationsEnabled,
                language: language
            )
        ]

        var request = makeRequest(url: url, method: "POST", accessToken: session.accessToken)
        request.setValue("resolution=merge-duplicates,return=representation", forHTTPHeaderField: "Prefer")
        request.httpBody = try JSONEncoder().encode(payload)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw SidebarProfileError.invalidResponse
        }
    }

    private func fetchProfileName(baseURL: URL, session: AuthSession) async throws -> String {
        guard var components = URLComponents(url: baseURL.appending(path: "/rest/v1/profiles"), resolvingAgainstBaseURL: false) else {
            throw URLError(.badURL)
        }

        components.queryItems = [
            URLQueryItem(name: "select", value: "full_name"),
            URLQueryItem(name: "id", value: "eq.\(session.userId)"),
            URLQueryItem(name: "limit", value: "1")
        ]

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        let rows: [ProfileRow] = try await executeGet(url: url, accessToken: session.accessToken)
        return rows.first?.fullName ?? session.userName
    }

    private func fetchPreferences(baseURL: URL, session: AuthSession) async throws -> PreferenceRow? {
        guard var components = URLComponents(url: baseURL.appending(path: "/rest/v1/user_preferences"), resolvingAgainstBaseURL: false) else {
            throw URLError(.badURL)
        }

        components.queryItems = [
            URLQueryItem(name: "select", value: "location_enabled,push_notifications_enabled,language"),
            URLQueryItem(name: "user_id", value: "eq.\(session.userId)"),
            URLQueryItem(name: "limit", value: "1")
        ]

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        let rows: [PreferenceRow] = try await executeGet(url: url, accessToken: session.accessToken)
        return rows.first
    }

    private func executeGet<T: Decodable>(url: URL, accessToken: String) async throws -> T {
        let request = makeRequest(url: url, method: "GET", accessToken: accessToken)
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw SidebarProfileError.invalidResponse
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw SidebarProfileError.invalidResponse
        }
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

private struct ProfileRow: Decodable {
    let fullName: String?

    private enum CodingKeys: String, CodingKey {
        case fullName = "full_name"
    }
}

private struct PreferenceRow: Decodable {
    let locationEnabled: Bool
    let pushNotificationsEnabled: Bool
    let language: String

    private enum CodingKeys: String, CodingKey {
        case locationEnabled = "location_enabled"
        case pushNotificationsEnabled = "push_notifications_enabled"
        case language
    }
}

private struct PreferencesUpsertPayload: Encodable {
    let userId: String
    let locationEnabled: Bool
    let pushNotificationsEnabled: Bool
    let language: String

    private enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case locationEnabled = "location_enabled"
        case pushNotificationsEnabled = "push_notifications_enabled"
        case language
    }
}
