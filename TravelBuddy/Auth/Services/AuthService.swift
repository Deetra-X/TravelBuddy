import Foundation

protocol AuthServiceProtocol {
    func login(email: String, password: String) async throws -> AuthUser
    func register(name: String, email: String, password: String) async throws -> AuthUser
    func requestPasswordResetCode(email: String) async throws -> String
    func verifyPasswordResetCode(email: String, code: String) async throws
    func resetPassword(email: String, newPassword: String) async throws
}

struct AuthService: AuthServiceProtocol {
    func login(email: String, password: String) async throws -> AuthUser {
        try await Task.sleep(for: .milliseconds(350))

        guard email.contains("@"), email.contains(".") else {
            throw AuthError.invalidEmail
        }

        guard password.count >= 8 else {
            throw AuthError.invalidPassword
        }

        return AuthUser(id: UUID(), name: "Traveler", email: email)
    }

    func register(name: String, email: String, password: String) async throws -> AuthUser {
        try await Task.sleep(for: .milliseconds(400))

        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AuthError.generic("Name is required.")
        }

        guard email.contains("@"), email.contains(".") else {
            throw AuthError.invalidEmail
        }

        guard password.count >= 8 else {
            throw AuthError.invalidPassword
        }

        return AuthUser(id: UUID(), name: name, email: email)
    }

    func requestPasswordResetCode(email: String) async throws -> String {
        try await Task.sleep(for: .milliseconds(350))

        guard email.contains("@"), email.contains(".") else {
            throw AuthError.invalidEmail
        }

        return UUID().uuidString
    }

    func verifyPasswordResetCode(email: String, code: String) async throws {
        try await Task.sleep(for: .milliseconds(350))

        guard email.contains("@"), email.contains(".") else {
            throw AuthError.invalidEmail
        }

        let normalizedCode = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalizedCode.count >= 4 else {
            throw AuthError.invalidOTP
        }
    }

    func resetPassword(email: String, newPassword: String) async throws {
        try await Task.sleep(for: .milliseconds(350))

        guard email.contains("@"), email.contains(".") else {
            throw AuthError.invalidEmail
        }

        guard newPassword.count >= 8 else {
            throw AuthError.invalidPassword
        }
    }
}
