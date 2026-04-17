import Foundation
import AuthenticationServices
import UIKit

protocol AuthServiceProtocol {
    func login(email: String, password: String) async throws -> AuthUser
    func loginWithGoogle() async throws -> AuthUser
    func register(name: String, email: String, password: String) async throws -> AuthUser
    func resendConfirmationEmail(email: String) async throws
    func requestPasswordResetCode(email: String) async throws -> String
    func verifyPasswordResetCode(email: String, code: String) async throws
    func resetPassword(email: String, newPassword: String) async throws
    func logout() async throws
}

struct AuthService: AuthServiceProtocol {
    private let session: URLSession
    private let sessionManager: SessionManagerProtocol

    init(session: URLSession = .shared, sessionManager: SessionManagerProtocol? = nil) {
        self.session = session
        self.sessionManager = sessionManager ?? SessionManager()
    }

    func login(email: String, password: String) async throws -> AuthUser {
        let normalizedEmail = email
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard AuthValidator.isValidEmail(normalizedEmail) else {
            throw AuthError.invalidEmail
        }

        guard password.count >= 8 else {
            throw AuthError.invalidPassword
        }

        guard AuthEndpoints.isConfigured,
              let url = AuthEndpoints.login else {
            throw AuthError.configurationMissing
        }

        let requestBody = SupabaseLoginRequest(email: normalizedEmail, password: password)
        let response = try await sendRequest(
            to: url,
            method: "POST",
            body: requestBody,
            responseType: SupabaseAuthResponse.self
        )

        guard let user = response.user else {
            throw AuthError.invalidCredentials
        }

        // Extract name safely
        let name: String
        if let metaName = user.userMetadata?.name {
            name = metaName
        } else if let fullName = user.userMetadata?.fullName {
            name = fullName
        } else if let emailPrefix = normalizedEmail.split(separator: "@").first {
            name = String(emailPrefix)
        } else {
            name = "Traveler"
        }

        // Calculate expiration date separately
        let expiresAt: Date?
        if let expiresIn = response.expiresIn {
            expiresAt = Date(timeIntervalSinceNow: TimeInterval(expiresIn))
        } else {
            expiresAt = nil
        }

        // Save session
        let accessToken = response.accessToken ?? ""
        let userEmail = user.email ?? normalizedEmail
        
        let authSession = AuthSession(
            accessToken: accessToken,
            refreshToken: response.refreshToken,
            userId: user.id,
            userEmail: userEmail,
            userName: name,
            expiresAt: expiresAt
        )
        
        try await sessionManager.saveSession(authSession)

        return AuthUser(id: user.id, name: name, email: userEmail)
    }

    func loginWithGoogle() async throws -> AuthUser {
        guard AuthEndpoints.isConfigured,
              let authorizeURL = AuthEndpoints.googleAuthorizeURL(redirectTo: SupabaseConfig.oAuthRedirectURLString),
              let userProfileURL = AuthEndpoints.userProfile else {
            throw AuthError.configurationMissing
        }

        let callbackURL = try await startOAuthSession(authorizeURL: authorizeURL)
        let callbackParameters = parseCallbackParameters(from: callbackURL)

        if let errorDescription = callbackParameters["error_description"] ?? callbackParameters["error"] {
            throw AuthError.network(errorDescription)
        }

        guard let accessToken = callbackParameters["access_token"], !accessToken.isEmpty else {
            throw AuthError.network("Google sign-in did not return an access token.")
        }

        let refreshToken = callbackParameters["refresh_token"]
        let expiresIn = Int(callbackParameters["expires_in"] ?? "")
        let user = try await fetchCurrentUser(accessToken: accessToken, url: userProfileURL)

        let resolvedEmail = user.email ?? ""
        let metadataFullName = user.userMetadata?.fullName
        let metadataName = user.userMetadata?.name
        let emailPrefix = resolvedEmail.split(separator: "@").first.map(String.init)
        let resolvedName = metadataFullName ?? metadataName ?? emailPrefix ?? "Traveler"

        let expiresAt: Date?
        if let expiresIn {
            expiresAt = Date(timeIntervalSinceNow: TimeInterval(expiresIn))
        } else {
            expiresAt = nil
        }

        let authSession = AuthSession(
            accessToken: accessToken,
            refreshToken: refreshToken,
            userId: user.id,
            userEmail: resolvedEmail,
            userName: resolvedName,
            expiresAt: expiresAt
        )

        try await sessionManager.saveSession(authSession)

        return AuthUser(id: user.id, name: resolvedName, email: resolvedEmail)
    }

    func register(name: String, email: String, password: String) async throws -> AuthUser {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedEmail = email
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard !trimmedName.isEmpty else {
            throw AuthError.generic("Name is required.")
        }

        guard AuthValidator.isValidEmail(normalizedEmail) else {
            throw AuthError.invalidEmail
        }

        guard password.count >= 8 else {
            throw AuthError.invalidPassword
        }

        guard AuthEndpoints.isConfigured,
              let url = AuthEndpoints.register else {
            throw AuthError.configurationMissing
        }

        let requestBody = SupabaseRegisterRequest(
            email: normalizedEmail,
            password: password,
            data: SupabaseRegisterData(name: trimmedName)
        )

        let response = try await sendRequest(
            to: url,
            method: "POST",
            body: requestBody,
            responseType: SupabaseAuthResponse.self
        )

        guard let user = response.user else {
            throw AuthError.generic("Account created. Please confirm your email before signing in.")
        }

        let userEmail = user.email ?? normalizedEmail

        return AuthUser(id: user.id, name: trimmedName, email: userEmail)
    }

    func resendConfirmationEmail(email: String) async throws {
        let normalizedEmail = email
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard AuthValidator.isValidEmail(normalizedEmail) else {
            throw AuthError.invalidEmail
        }

        guard AuthEndpoints.isConfigured,
              let url = AuthEndpoints.resendConfirmation else {
            throw AuthError.configurationMissing
        }

        _ = try await sendRequest(
            to: url,
            method: "POST",
            body: SupabaseResendConfirmationRequest(email: normalizedEmail),
            responseType: EmptyResponse.self
        )
    }

    func requestPasswordResetCode(email: String) async throws -> String {
        let normalizedEmail = email
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard AuthValidator.isValidEmail(normalizedEmail) else {
            throw AuthError.invalidEmail
        }

        guard AuthEndpoints.isConfigured,
              let url = AuthEndpoints.requestResetCode else {
            throw AuthError.configurationMissing
        }

        _ = try await sendRequest(
            to: url,
            method: "POST",
            body: SupabaseRecoverRequest(email: normalizedEmail),
            responseType: EmptyResponse.self
        )

        return UUID().uuidString
    }

    func verifyPasswordResetCode(email: String, code: String) async throws {
        let normalizedEmail = email
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard AuthValidator.isValidEmail(normalizedEmail) else {
            throw AuthError.invalidEmail
        }

        let normalizedCode = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalizedCode.count >= 6 else {
            throw AuthError.invalidOTP
        }

        guard AuthEndpoints.isConfigured,
              let url = AuthEndpoints.verifyResetCode else {
            throw AuthError.configurationMissing
        }

        _ = try await sendRequest(
            to: url,
            method: "POST",
            body: SupabaseVerifyRecoveryRequest(email: normalizedEmail, token: normalizedCode),
            responseType: SupabaseAuthResponse.self
        )
    }

    func resetPassword(email: String, newPassword: String) async throws {
        let normalizedEmail = email
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard AuthValidator.isValidEmail(normalizedEmail) else {
            throw AuthError.invalidEmail
        }

        guard newPassword.count >= 8 else {
            throw AuthError.invalidPassword
        }

        throw AuthError.generic("Password reset update requires an active recovery session token. Login is fully connected to Supabase; I can wire full recovery token flow next.")
    }

    func logout() async throws {
        try await sessionManager.clearSession()
    }

    private func sendRequest<RequestBody: Encodable, ResponseBody: Decodable>(
        to url: URL,
        method: String,
        body: RequestBody,
        responseType: ResponseBody.Type
    ) async throws -> ResponseBody {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.network("Invalid server response.")
        }

        if (200..<300).contains(httpResponse.statusCode) {
            if data.isEmpty, let empty = EmptyResponse() as? ResponseBody {
                return empty
            }

            do {
                return try JSONDecoder().decode(responseType, from: data)
            } catch {
                if let empty = EmptyResponse() as? ResponseBody {
                    return empty
                }
                throw AuthError.network("Failed to decode server response.")
            }
        }

        if let serverError = try? JSONDecoder().decode(SupabaseErrorResponse.self, from: data) {
            throw AuthError.network(serverError.userMessage)
        }

        throw AuthError.network("Request failed with status code \(httpResponse.statusCode).")
    }

    private func startOAuthSession(authorizeURL: URL) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                let presentationProvider = OAuthPresentationContextProvider()
                let session = ASWebAuthenticationSession(
                    url: authorizeURL,
                    callbackURLScheme: SupabaseConfig.oAuthCallbackScheme
                ) { callbackURL, error in
                    if let error {
                        continuation.resume(throwing: AuthError.network(error.localizedDescription))
                        return
                    }

                    guard let callbackURL else {
                        continuation.resume(throwing: AuthError.network("Google sign-in callback was empty."))
                        return
                    }

                    continuation.resume(returning: callbackURL)
                }

                session.presentationContextProvider = presentationProvider
                session.prefersEphemeralWebBrowserSession = true
                presentationProvider.session = session

                if !session.start() {
                    continuation.resume(throwing: AuthError.network("Unable to start Google sign-in session."))
                }
            }
        }
    }

    private func parseCallbackParameters(from url: URL) -> [String: String] {
        var parameters: [String: String] = [:]

        if let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems {
            for item in queryItems {
                parameters[item.name] = item.value
            }
        }

        if let fragment = url.fragment {
            for pair in fragment.split(separator: "&") {
                let parts = pair.split(separator: "=", maxSplits: 1)
                guard let rawKey = parts.first else { continue }
                let rawValue = parts.count > 1 ? String(parts[1]) : ""
                let key = String(rawKey).removingPercentEncoding ?? String(rawKey)
                let value = rawValue.removingPercentEncoding ?? rawValue
                parameters[key] = value
            }
        }

        return parameters
    }

    private func fetchCurrentUser(accessToken: String, url: URL) async throws -> SupabaseUser {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.network("Invalid server response.")
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            if let serverError = try? JSONDecoder().decode(SupabaseErrorResponse.self, from: data) {
                throw AuthError.network(serverError.userMessage)
            }
            throw AuthError.network("Failed to load Google account profile.")
        }

        do {
            return try JSONDecoder().decode(SupabaseUser.self, from: data)
        } catch {
            throw AuthError.network("Failed to decode Google account profile.")
        }
    }
}

private final class OAuthPresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    var session: ASWebAuthenticationSession?

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: \.isKeyWindow) ?? ASPresentationAnchor()
    }
}

private enum AuthValidator {
    static func isValidEmail(_ email: String) -> Bool {
        let pattern = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: email)
    }
}

private struct SupabaseLoginRequest: Encodable {
    let email: String
    let password: String
}

private struct SupabaseRegisterRequest: Encodable {
    let email: String
    let password: String
    let data: SupabaseRegisterData
}

private struct SupabaseRegisterData: Encodable {
    let name: String
}

private struct SupabaseRecoverRequest: Encodable {
    let email: String
}

private struct SupabaseResendConfirmationRequest: Encodable {
    let email: String
    let type: String = "signup"
}

private struct SupabaseVerifyRecoveryRequest: Encodable {
    let email: String
    let token: String
    let type: String = "recovery"
}

private struct SupabaseAuthResponse: Decodable {
    let user: SupabaseUser?
    let accessToken: String?
    let refreshToken: String?
    let expiresIn: Int?
    
    private enum CodingKeys: String, CodingKey {
        case user
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
    }
}

private struct SupabaseUser: Decodable {
    let id: String
    let email: String?
    let userMetadata: SupabaseUserMetadata?

    private enum CodingKeys: String, CodingKey {
        case id
        case email
        case userMetadata = "user_metadata"
    }
}

private struct SupabaseUserMetadata: Decodable {
    let name: String?
    let fullName: String?

    private enum CodingKeys: String, CodingKey {
        case name
        case fullName = "full_name"
    }
}

private struct SupabaseErrorResponse: Decodable {
    let error: String?
    let errorDescription: String?
    let msg: String?
    let message: String?

    var userMessage: String {
        errorDescription ?? msg ?? message ?? error ?? "Authentication failed."
    }

    private enum CodingKeys: String, CodingKey {
        case error
        case errorDescription = "error_description"
        case msg
        case message
    }
}

private struct EmptyResponse: Codable {}
