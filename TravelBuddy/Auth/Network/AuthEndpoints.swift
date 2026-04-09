import Foundation

struct AuthEndpoints {
    static let baseURL = URL(string: "https://your-api-domain.com")!

    static let login = "/api/v1/auth/login"
    static let register = "/api/v1/auth/register"
    static let requestResetCode = "/api/v1/auth/password/request-code"
    static let verifyResetCode = "/api/v1/auth/password/verify-code"
    static let resetPassword = "/api/v1/auth/password/reset"
}
