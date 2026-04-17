import Foundation

struct AuthEndpoints {
    static var isConfigured: Bool {
        guard let url = URL(string: SupabaseConfig.projectURLString),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              url.host != nil else {
            return false
        }

        return !SupabaseConfig.anonKey
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty
    }

    static var baseURL: URL? {
        URL(string: SupabaseConfig.projectURLString)
    }

    static var login: URL? {
        guard let tokenURL = baseURL?.appending(path: "/auth/v1/token"),
              var components = URLComponents(url: tokenURL, resolvingAgainstBaseURL: false) else {
            return nil
        }
        components.queryItems = [URLQueryItem(name: "grant_type", value: "password")]
        return components.url
    }

    static var register: URL? {
        baseURL?.appending(path: "/auth/v1/signup")
    }

    static var requestResetCode: URL? {
        baseURL?.appending(path: "/auth/v1/recover")
    }

    static var verifyResetCode: URL? {
        baseURL?.appending(path: "/auth/v1/verify")
    }

    static var resetPassword: URL? {
        baseURL?.appending(path: "/auth/v1/user")
    }

    static var resendConfirmation: URL? {
        baseURL?.appending(path: "/auth/v1/resend")
    }

    static var userProfile: URL? {
        baseURL?.appending(path: "/auth/v1/user")
    }

    static func googleAuthorizeURL(redirectTo: String) -> URL? {
        guard let authorizeURL = baseURL?.appending(path: "/auth/v1/authorize"),
              var components = URLComponents(url: authorizeURL, resolvingAgainstBaseURL: false) else {
            return nil
        }

        components.queryItems = [
            URLQueryItem(name: "provider", value: "google"),
            URLQueryItem(name: "redirect_to", value: redirectTo)
        ]

        return components.url
    }
}

enum SupabaseConfig {
    static let projectURLString = "https://vnqqgxyakcbkeoualauc.supabase.co"
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZucXFneHlha2Nia2VvdWFsYXVjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU3NTUyNTIsImV4cCI6MjA5MTMzMTI1Mn0.UH8g9MxE6g477evC-y6-bDFi-DJ3Y9DTgcTIWrhm4c0"
    static let oAuthCallbackScheme = "travelbuddy"
    static let oAuthCallbackHost = "auth-callback"

    static var oAuthRedirectURLString: String {
        "\(oAuthCallbackScheme)://\(oAuthCallbackHost)"
    }
}
