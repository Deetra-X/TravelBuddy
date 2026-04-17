import Foundation
import Combine
import Security

// MARK: - Session Manager Protocol
protocol SessionManagerProtocol {
    var currentSession: AuthSession? { get }
    var isAuthenticated: Bool { get }
    
    func saveSession(_ session: AuthSession) async throws
    func loadSession() async -> AuthSession?
    func clearSession() async throws
    func refreshToken(_ refreshToken: String) async throws -> String
}

// MARK: - Auth Session Model
struct AuthSession: Codable {
    let accessToken: String
    let refreshToken: String?
    let userId: String
    let userEmail: String
    let userName: String
    let expiresAt: Date?
    
    var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return Date() >= expiresAt
    }
}

// MARK: - Session Manager Implementation
@MainActor
final class SessionManager: SessionManagerProtocol, ObservableObject {
    @Published private(set) var currentSession: AuthSession?
    
    var isAuthenticated: Bool {
        guard let session = currentSession else { return false }
        return !session.isExpired
    }
    
    private let keychainHelper = KeychainHelper()
    private let userDefaultsHelper = UserDefaultsHelper()
    
    nonisolated private let sessionQueue = DispatchQueue(label: "com.travelbuddy.session", attributes: .concurrent)
    
    init() {
        Task {
            self.currentSession = await loadSession()
        }
    }
    
    func saveSession(_ session: AuthSession) async throws {
        await MainActor.run {
            self.currentSession = session
        }
        
        // Save to Keychain
        try keychainHelper.save(session)
        
        // Save user info to UserDefaults for quick access
        userDefaultsHelper.saveUserInfo(
            id: session.userId,
            email: session.userEmail,
            name: session.userName
        )
    }
    
    func loadSession() async -> AuthSession? {
        guard let session = keychainHelper.load() else {
            return nil
        }
        
        if !session.isExpired {
            return session
        } else {
            // Session expired, clear it
            try? await clearSession()
            return nil
        }
    }
    
    func clearSession() async throws {
        await MainActor.run {
            self.currentSession = nil
        }
        
        keychainHelper.delete()
        userDefaultsHelper.clearUserInfo()
    }
    
    func refreshToken(_ refreshToken: String) async throws -> String {
        guard let baseURL = URL(string: SupabaseConfig.projectURLString) else {
            throw AuthError.configurationMissing
        }
        
        let url = baseURL.appending(path: "/auth/v1/token")
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "grant_type", value: "refresh_token")]
        
        guard let tokenURL = components?.url else {
            throw AuthError.configurationMissing
        }
        
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        
        let body = RefreshTokenRequest(refreshToken: refreshToken)
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw AuthError.network("Failed to refresh token")
        }
        
        let tokenResponse = try JSONDecoder().decode(RefreshTokenResponse.self, from: data)
        return tokenResponse.accessToken
    }
}

// MARK: - Keychain Helper
private class KeychainHelper {
    private let service = "com.travelbuddy.auth"
    private let account = "session"
    
    func save(_ session: AuthSession) throws {
        let data = try JSONEncoder().encode(session)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing before saving new
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }
    
    func load() -> AuthSession? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data else {
            return nil
        }
        
        return try? JSONDecoder().decode(AuthSession.self, from: data)
    }
    
    func delete() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - UserDefaults Helper
// MARK: - Keychain Error
enum KeychainError: LocalizedError {
    case saveFailed(OSStatus)
    case deleteFailed(OSStatus)
    
    var errorDescription: String? {
        switch self {
        case .saveFailed:
            return "Failed to save to Keychain"
        case .deleteFailed:
            return "Failed to delete from Keychain"
        }
    }
}

// MARK: - Token Refresh Request/Response
private struct RefreshTokenRequest: Encodable {
    let refreshToken: String
    
    private enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }
}

private struct RefreshTokenResponse: Decodable {
    let accessToken: String
    
    private enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
    }
}
