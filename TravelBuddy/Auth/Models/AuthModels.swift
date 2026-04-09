import Foundation

struct AuthUser: Equatable {
    let id: UUID
    let name: String
    let email: String
}

enum AuthError: LocalizedError {
    case invalidCredentials
    case invalidEmail
    case invalidPassword
    case invalidOTP
    case passwordsDoNotMatch
    case generic(String)

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid credentials. Please check your email and password."
        case .invalidEmail:
            return "Please enter a valid email address."
        case .invalidPassword:
            return "Password must be at least 8 characters."
        case .invalidOTP:
            return "Invalid OTP code. Please try again."
        case .passwordsDoNotMatch:
            return "Passwords do not match."
        case .generic(let message):
            return message
        }
    }
}

struct PasswordResetContext {
    var email: String = ""
    var requestId: String = ""
    var isOTPVerified: Bool = false
}
