import SwiftUI

struct AdvancedSettingsScreen: View {
    @EnvironmentObject private var sessionManager: SessionManager
    @EnvironmentObject private var ongoingTripViewModel: OngoingTripViewModel

    var onClose: () -> Void
    var onLogout: () -> Void

    @State private var showClearHistoryAlert = false
    @State private var showClearTripAlert = false
    @State private var showDeleteAccountAlert = false
    @State private var isProcessing = false
    @State private var successMessage: String?
    @State private var errorMessage: String?

    private let accountService = AdvancedSettingsAccountService()

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                if let message = errorMessage {
                    AuthErrorBanner(message: message)
                }

                if let message = successMessage {
                    AuthSuccessBanner(message: message)
                }

                Text("Manage your advanced account data and actions.")
                    .font(.subheadline)
                    .foregroundStyle(Color.travelBody)

                advancedRow(
                    icon: "clock.arrow.circlepath",
                    title: "Clear History",
                    subtitle: "Remove search and activity history",
                    tint: Color.travelTitle
                ) {
                    showClearHistoryAlert = true
                }

                advancedRow(
                    icon: "suitcase.rolling",
                    title: "Clear Trip",
                    subtitle: "Remove saved trip plans and local trip data",
                    tint: Color.travelTitle
                ) {
                    showClearTripAlert = true
                }

                advancedRow(
                    icon: "trash",
                    title: "Delete Account",
                    subtitle: "Permanently remove your account and data",
                    tint: .red
                ) {
                    showDeleteAccountAlert = true
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .background(Color.travelBackground.ignoresSafeArea())
            .navigationTitle("Advanced Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        onClose()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundStyle(Color.travelTitle)
                    }
                }
            }
            .alert("Clear History", isPresented: $showClearHistoryAlert) {
                Button("Clear", role: .destructive) {
                    Task {
                        await clearHistory()
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will clear your history.")
            }
            .alert("Clear Trip", isPresented: $showClearTripAlert) {
                Button("Clear", role: .destructive) {
                    Task {
                        await clearTrips()
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will clear your trip data.")
            }
            .alert("Delete Account", isPresented: $showDeleteAccountAlert) {
                Button("Delete", role: .destructive) {
                    Task {
                        await deleteAccount()
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }

    @ViewBuilder
    private func advancedRow(
        icon: String,
        title: String,
        subtitle: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(tint)
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(tint)

                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(Color.travelBody)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(Color.travelBody)
                    .padding(.top, 3)
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .disabled(isProcessing)
    }

    @MainActor
    private func clearHistory() async {
        guard !isProcessing else { return }
        isProcessing = true
        defer { isProcessing = false }

        errorMessage = nil
        successMessage = nil

        let defaults = UserDefaults.standard
        UserDefaultsHelper().clearUserPreferences()

        if let userId = sessionManager.currentSession?.userId {
            defaults.removeObject(forKey: "com.travelbuddy.sidebar.profile.preferences.\(userId)")
        }

        removeUserDefaultsKeys(containing: "history")
        successMessage = "History cleared."
    }

    @MainActor
    private func clearTrips() async {
        guard !isProcessing else { return }
        isProcessing = true
        defer { isProcessing = false }

        errorMessage = nil
        successMessage = nil

        guard let session = sessionManager.currentSession else {
            errorMessage = "Please sign in again and try."
            return
        }

        let didClearRemoteTrips = await ongoingTripViewModel.clearAllTrips(session: session)
        ongoingTripViewModel.clearLocalCache(for: session.userId)

        if didClearRemoteTrips {
            successMessage = "Trip data cleared."
        } else {
            errorMessage = ongoingTripViewModel.errorMessage ?? "Could not clear all trip data."
        }
    }

    @MainActor
    private func deleteAccount() async {
        guard !isProcessing else { return }
        isProcessing = true
        defer { isProcessing = false }

        errorMessage = nil
        successMessage = nil

        guard let session = sessionManager.currentSession else {
            errorMessage = "Please sign in again and try."
            return
        }

        do {
            try await accountService.deleteAccount(session: session)
            try? await sessionManager.clearSession()
            onLogout()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func removeUserDefaultsKeys(containing token: String) {
        let defaults = UserDefaults.standard
        for key in defaults.dictionaryRepresentation().keys where key.localizedCaseInsensitiveContains(token) {
            defaults.removeObject(forKey: key)
        }
    }
}

private struct AdvancedSettingsAccountService {
    enum AdvancedSettingsError: LocalizedError {
        case missingConfiguration
        case invalidResponse

        var errorDescription: String? {
            switch self {
            case .missingConfiguration:
                return "Supabase is not configured."
            case .invalidResponse:
                return "Failed to delete account."
            }
        }
    }

    func deleteAccount(session: AuthSession) async throws {
        guard AuthEndpoints.isConfigured,
              let baseURL = AuthEndpoints.baseURL else {
            throw AdvancedSettingsError.missingConfiguration
        }

        let url = baseURL.appending(path: "/auth/v1/user")
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AdvancedSettingsError.invalidResponse
        }
    }
}
