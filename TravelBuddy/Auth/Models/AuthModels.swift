import Foundation

struct AuthUser: Equatable {
    let id: String
    let name: String
    let email: String
}

enum AuthError: LocalizedError {
    case invalidCredentials
    case invalidEmail
    case invalidPassword
    case invalidOTP
    case passwordsDoNotMatch
    case configurationMissing
    case network(String)
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
        case .configurationMissing:
            return "Supabase is not configured. Add your project URL and anon key in SupabaseConfig."
        case .network(let message):
            return message
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
