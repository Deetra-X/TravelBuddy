import Foundation

struct SidebarUserDetails: Equatable {
    let userId: String
    let fullName: String
    let email: String
    let dateOfBirth: String
    let locationEnabled: Bool
    let pushNotificationsEnabled: Bool
    let language: String
}

protocol SidebarProfileServiceProtocol {
    func fetchUserDetails(session: AuthSession) async throws -> SidebarUserDetails
    func saveUserDetails(
        session: AuthSession,
        fullName: String,
        email: String,
        dateOfBirth: String,
        password: String?
    ) async throws -> SidebarUserDetails
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
        let dateOfBirth = try await fetchDateOfBirth(baseURL: baseURL, session: session)
        let preferences = try await fetchPreferences(baseURL: baseURL, session: session)

        let resolvedName = profileName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty ? session.userName : profileName

        return SidebarUserDetails(
            userId: session.userId,
            fullName: resolvedName,
            email: session.userEmail,
            dateOfBirth: dateOfBirth ?? "",
            locationEnabled: preferences?.locationEnabled ?? true,
            pushNotificationsEnabled: preferences?.pushNotificationsEnabled ?? false,
            language: preferences?.language ?? "English"
        )
    }

    func saveUserDetails(
        session: AuthSession,
        fullName: String,
        email: String,
        dateOfBirth: String,
        password: String?
    ) async throws -> SidebarUserDetails {
        guard AuthEndpoints.isConfigured, let baseURL = AuthEndpoints.baseURL else {
            throw SidebarProfileError.missingConfiguration
        }

        let trimmedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let trimmedDateOfBirth = dateOfBirth.trimmingCharacters(in: .whitespacesAndNewlines)

        try await updateProfile(
            baseURL: baseURL,
            session: session,
            fullName: trimmedName,
            dateOfBirth: trimmedDateOfBirth
        )

        if !trimmedEmail.isEmpty, trimmedEmail != session.userEmail {
            try await updateAuthUser(
                baseURL: baseURL,
                session: session,
                email: trimmedEmail,
                password: nil
            )
        }

        if let password {
            let normalizedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
            if !normalizedPassword.isEmpty {
                try await updateAuthUser(
                    baseURL: baseURL,
                    session: session,
                    email: nil,
                    password: normalizedPassword
                )
            }
        }

        let updatedDetails = try await fetchUserDetails(session: session)
        return SidebarUserDetails(
            userId: updatedDetails.userId,
            fullName: updatedDetails.fullName,
            email: trimmedEmail.isEmpty ? updatedDetails.email : trimmedEmail,
            dateOfBirth: updatedDetails.dateOfBirth,
            locationEnabled: updatedDetails.locationEnabled,
            pushNotificationsEnabled: updatedDetails.pushNotificationsEnabled,
            language: updatedDetails.language
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

    private func fetchDateOfBirth(baseURL: URL, session: AuthSession) async throws -> String? {
        guard var components = URLComponents(url: baseURL.appending(path: "/rest/v1/profiles"), resolvingAgainstBaseURL: false) else {
            throw URLError(.badURL)
        }

        components.queryItems = [
            URLQueryItem(name: "select", value: "date_of_birth"),
            URLQueryItem(name: "id", value: "eq.\(session.userId)"),
            URLQueryItem(name: "limit", value: "1")
        ]

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        let rows: [ProfileRow] = try await executeGet(url: url, accessToken: session.accessToken)
        return rows.first?.dateOfBirth
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

    private func updateProfile(
        baseURL: URL,
        session: AuthSession,
        fullName: String,
        dateOfBirth: String
    ) async throws {
        guard var components = URLComponents(url: baseURL.appending(path: "/rest/v1/profiles"), resolvingAgainstBaseURL: false) else {
            throw URLError(.badURL)
        }

        components.queryItems = [
            URLQueryItem(name: "id", value: "eq.\(session.userId)")
        ]

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        let payload = ProfileUpdatePayload(
            fullName: fullName.isEmpty ? session.userName : fullName,
            dateOfBirth: dateOfBirth.isEmpty ? nil : dateOfBirth
        )

        var request = makeRequest(url: url, method: "PATCH", accessToken: session.accessToken)
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        request.httpBody = try JSONEncoder().encode(payload)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw SidebarProfileError.invalidResponse
        }
    }

    private func updateAuthUser(
        baseURL: URL,
        session: AuthSession,
        email: String?,
        password: String?
    ) async throws {
        let url = baseURL.appending(path: "/auth/v1/user")
        var request = makeRequest(url: url, method: "PUT", accessToken: session.accessToken)

        let payload = AuthUserUpdatePayload(email: email, password: password)
        request.httpBody = try JSONEncoder().encode(payload)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
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
    let dateOfBirth: String?

    private enum CodingKeys: String, CodingKey {
        case fullName = "full_name"
        case dateOfBirth = "date_of_birth"
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

private struct ProfileUpdatePayload: Encodable {
    let fullName: String
    let dateOfBirth: String?

    private enum CodingKeys: String, CodingKey {
        case fullName = "full_name"
        case dateOfBirth = "date_of_birth"
    }
}

private struct AuthUserUpdatePayload: Encodable {
    let email: String?
    let password: String?
}
