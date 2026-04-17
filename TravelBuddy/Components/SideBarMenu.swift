import SwiftUI
import Combine

struct SideBarMenu: View {
    @EnvironmentObject private var sessionManager: SessionManager

    var onClose: () -> Void
    var onLogout: () -> Void
    var onAdvancedSettings: () -> Void

    @StateObject private var viewModel = SideBarMenuViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack {
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.subheadline)
                        .foregroundStyle(Color.travelTitle)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 12) {
                Circle()
                    .fill(Color.travelPrimary.opacity(0.2))
                    .frame(width: 64, height: 64)
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.title2)
                            .foregroundStyle(Color.travelPrimary)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.fullName)
                        .font(.subheadline)
                    Text(viewModel.email)
                        .font(.subheadline)
                        .foregroundStyle(Color.travelBody)
                }

                Spacer()

                Button("Edit Profile") { }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .frame(height: 36)
                    .background(Capsule().fill(Color.travelPrimary))
            }

            Text("Preferences")
                .font(.subheadline)
                .padding(.top, 4)

            menuRow(icon: "location", title: "Location") {
                Toggle("", isOn: Binding(
                    get: { viewModel.locationEnabled },
                    set: { newValue in
                        viewModel.locationEnabled = newValue
                        Task {
                            await viewModel.persistPreferences(session: sessionManager.currentSession)
                        }
                    }
                ))
                    .labelsHidden()
                    .tint(Color.travelPrimary)
            }

            menuRow(icon: "globe", title: "Language") {
                Menu {
                    Button("English") {
                        viewModel.language = "English"
                        Task {
                            await viewModel.persistPreferences(session: sessionManager.currentSession)
                        }
                    }
                    Button("Spanish") {
                        viewModel.language = "Spanish"
                        Task {
                            await viewModel.persistPreferences(session: sessionManager.currentSession)
                        }
                    }
                    Button("French") {
                        viewModel.language = "French"
                        Task {
                            await viewModel.persistPreferences(session: sessionManager.currentSession)
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(viewModel.language)
                            .font(.subheadline)
                            .foregroundStyle(Color.travelBody)
                        Image(systemName: "chevron.right")
                            .foregroundStyle(Color.travelTitle)
                    }
                }
            }

            menuRow(icon: "bell", title: "Push Notifications") {
                Toggle("", isOn: Binding(
                    get: { viewModel.pushEnabled },
                    set: { newValue in
                        viewModel.pushEnabled = newValue
                        Task {
                            await viewModel.persistPreferences(session: sessionManager.currentSession)
                        }
                    }
                ))
                    .labelsHidden()
                    .tint(Color.travelPrimary)
            }

            Spacer()

            menuRow(icon: "gearshape.2", title: "Advanced Settings") {
                Button {
                    onAdvancedSettings()
                } label: {
                    Image(systemName: "chevron.right")
                        .foregroundStyle(Color.travelTitle)
                }
                .buttonStyle(.plain)
            }

            Button(action: onLogout) {
                HStack(spacing: 6) {
                    Image(systemName: "rectangle.portrait.and.arrow.forward")
                        .font(.caption)
                    Text("Logout")
                }
                .font(.caption)
                .foregroundStyle(.white)
                .frame(height: 32)
                .frame(maxWidth: 110)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.red)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.travelBackground)
        .task(id: sessionManager.currentSession?.userId) {
            await viewModel.load(session: sessionManager.currentSession)
        }
    }

    @ViewBuilder
    private func menuRow<Accessory: View>(icon: String, title: String, @ViewBuilder accessory: () -> Accessory) -> some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 22)
                .foregroundStyle(Color.travelPrimary)

            Text(title)
                .font(.body)
                .foregroundStyle(Color.travelTitle)

            Spacer()

            accessory()
        }
        .frame(height: 34)
    }
}

@MainActor
private final class SideBarMenuViewModel: ObservableObject {
    @Published var fullName: String = "Traveler"
    @Published var email: String = ""
    @Published var locationEnabled: Bool = true
    @Published var pushEnabled: Bool = false
    @Published var language: String = "English"

    private let service: SidebarProfileServiceProtocol

    init(service: SidebarProfileServiceProtocol? = nil) {
        self.service = service ?? SidebarProfileService()
    }

    func load(session: AuthSession?) async {
        guard let session else {
            fullName = "Traveler"
            email = ""
            locationEnabled = true
            pushEnabled = false
            language = "English"
            return
        }

        do {
            let details = try await service.fetchUserDetails(session: session)
            fullName = details.fullName
            email = details.email
            locationEnabled = details.locationEnabled
            pushEnabled = details.pushNotificationsEnabled
            language = details.language
        } catch {
            fullName = session.userName
            email = session.userEmail
        }
    }

    func persistPreferences(session: AuthSession?) async {
        guard let session else { return }

        do {
            try await service.savePreferences(
                session: session,
                locationEnabled: locationEnabled,
                pushNotificationsEnabled: pushEnabled,
                language: language
            )
        } catch {
            return
        }
    }
}
