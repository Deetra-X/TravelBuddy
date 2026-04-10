import Foundation
import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var currentUser: AuthUser?
    @Published var resetContext = PasswordResetContext()

    private let service: AuthServiceProtocol
    private let sessionManager: SessionManagerProtocol?

    init(service: AuthServiceProtocol, sessionManager: SessionManagerProtocol? = nil) {
        self.service = service
        self.sessionManager = sessionManager
    }

    convenience init() {
        let sessionManager = SessionManager()
        self.init(service: AuthService(sessionManager: sessionManager), sessionManager: sessionManager)
    }

    func clearError() {
        errorMessage = nil
        successMessage = nil
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
            _ = try await service.register(name: name, email: email, password: password)
            successMessage = "Account is created."
            return true
        } catch {
            let message = readable(error)
            if message.lowercased().contains("account created") {
                successMessage = "Account is created."
                return true
            }

            errorMessage = message
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

    func resendConfirmationEmail(email: String) async -> Bool {
        clearError()
        isLoading = true
        defer { isLoading = false }

        do {
            try await service.resendConfirmationEmail(email: email)
            successMessage = "Verification email sent. Please check your inbox."
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

    func logout() async {
        isLoading = true
        defer { isLoading = false }
        
        currentUser = nil
        try? await service.logout()
        try? await sessionManager?.clearSession()
    }

    private func readable(_ error: Error) -> String {
        if let localized = error as? LocalizedError {
            let message = localized.errorDescription ?? "Something went wrong."
            if message.lowercased().contains("email not confirmed") {
                return "Email confirmation is enabled in Supabase. Disable it in Authentication > Providers > Email to allow immediate login."
            }
            return message
        }
        let message = error.localizedDescription
        if message.lowercased().contains("email not confirmed") {
            return "Email confirmation is enabled in Supabase. Disable it in Authentication > Providers > Email to allow immediate login."
        }
        return message
    }
}
