import Foundation
import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentUser: AuthUser?
    @Published var resetContext = PasswordResetContext()

    private let service: AuthServiceProtocol

    init(service: AuthServiceProtocol) {
        self.service = service
    }

    convenience init() {
        self.init(service: AuthService())
    }

    func clearError() {
        errorMessage = nil
    }

    func login(email: String, password: String) async -> Bool {
        clearError()
        isLoading = true
        defer { isLoading = false }

        do {
            currentUser = try await service.login(email: email, password: password)
            return true
        } catch {
            errorMessage = readable(error)
            return false
        }
    }

    func register(name: String, email: String, password: String) async -> Bool {
        clearError()
        isLoading = true
        defer { isLoading = false }

        do {
            currentUser = try await service.register(name: name, email: email, password: password)
            return true
        } catch {
            errorMessage = readable(error)
            return false
        }
    }

    func requestPasswordResetCode(email: String) async -> Bool {
        clearError()
        isLoading = true
        defer { isLoading = false }

        do {
            let requestId = try await service.requestPasswordResetCode(email: email)
            resetContext.email = email
            resetContext.requestId = requestId
            resetContext.isOTPVerified = false
            return true
        } catch {
            errorMessage = readable(error)
            return false
        }
    }

    func verifyPasswordResetCode(code: String) async -> Bool {
        clearError()
        isLoading = true
        defer { isLoading = false }

        do {
            try await service.verifyPasswordResetCode(email: resetContext.email, code: code)
            resetContext.isOTPVerified = true
            return true
        } catch {
            errorMessage = readable(error)
            return false
        }
    }

    func resetPassword(newPassword: String, confirmPassword: String) async -> Bool {
        clearError()

        guard newPassword == confirmPassword else {
            errorMessage = AuthError.passwordsDoNotMatch.errorDescription
            return false
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await service.resetPassword(email: resetContext.email, newPassword: newPassword)
            return true
        } catch {
            errorMessage = readable(error)
            return false
        }
    }

    func signOut() {
        currentUser = nil
    }

    private func readable(_ error: Error) -> String {
        if let localized = error as? LocalizedError {
            return localized.errorDescription ?? "Something went wrong."
        }
        return error.localizedDescription
    }
}
