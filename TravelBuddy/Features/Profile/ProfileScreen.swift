import SwiftUI
import PhotosUI
import UIKit
import Combine

struct ProfileScreen: View {
    @EnvironmentObject private var sessionManager: SessionManager
    @StateObject private var viewModel = ProfileScreenViewModel()
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var profileImage: UIImage?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                topBar

                if let message = viewModel.errorMessage {
                    AuthErrorBanner(message: message)
                }

                if let message = viewModel.successMessage {
                    AuthSuccessBanner(message: message)
                }

                avatarSection

                Group {
                    inputField(title: "Name", text: $viewModel.fullName)
                    inputField(title: "Email", text: $viewModel.email, keyboardType: .emailAddress)
                    passwordField
                    dateOfBirthField
                }

                Button {
                    Task {
                        await saveProfile()
                    }
                } label: {
                    Text(viewModel.isSaving ? "Saving..." : "Save")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.blue)
                        )
                }
                .buttonStyle(.plain)
                .padding(.top, 10)
                .disabled(viewModel.isSaving || sessionManager.currentSession == nil)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 120)
        }
        .background(Color.travelBackground.ignoresSafeArea())
        .task(id: sessionManager.currentSession?.userId) {
            await viewModel.load(session: sessionManager.currentSession)
        }
        .onChange(of: selectedPhotoItem) {
            Task {
                await loadProfileImage(from: selectedPhotoItem)
            }
        }
    }

    private var topBar: some View {
        HStack {
            Text("Edit Profile")
                .font(.headline)
                .foregroundStyle(Color.travelTitle)

            Spacer()
        }
        .padding(.top, 4)
    }

    private var avatarSection: some View {
        HStack {
            Spacer()

            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color.white)
                    .frame(width: 134, height: 134)
                    .overlay {
                        if let profileImage {
                            Image(uiImage: profileImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 128, height: 128)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.fill")
                                .font(.system(size: 52))
                                .foregroundStyle(Color.travelPrimary.opacity(0.8))
                        }
                    }
                    .overlay(
                        Circle()
                            .stroke(Color.travelPrimary.opacity(0.4), lineWidth: 1)
                    )

                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Circle()
                        .fill(Color.travelPrimary)
                        .frame(width: 30, height: 30)
                        .overlay {
                            Image(systemName: "camera.fill")
                                .font(.caption)
                                .foregroundStyle(.white)
                        }
                }
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }

    private func inputField(title: String, text: Binding<String>, keyboardType: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.travelTitle)

            TextField("", text: text)
                .keyboardType(keyboardType)
                .autocapitalization(.none)
                .textInputAutocapitalization(.never)
                .font(.body)
                .padding(.horizontal, 12)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.white.opacity(0.35))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.gray.opacity(0.22), lineWidth: 1)
                        )
                )
        }
    }

    private var passwordField: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Password")
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.travelTitle)

            SecureField("Leave blank to keep current password", text: $viewModel.password)
                .font(.body)
                .padding(.horizontal, 12)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.white.opacity(0.35))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.gray.opacity(0.22), lineWidth: 1)
                        )
                )
        }
    }

    private var dateOfBirthField: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Date of Birth")
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.travelTitle)

            DatePicker(
                "",
                selection: $viewModel.dateOfBirth,
                displayedComponents: .date
            )
            .labelsHidden()
            .datePickerStyle(.compact)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.white.opacity(0.35))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.gray.opacity(0.22), lineWidth: 1)
                    )
            )
        }
    }

    @MainActor
    private func saveProfile() async {
        guard let session = sessionManager.currentSession else { return }

        if let updatedSession = await viewModel.save(session: session) {
            try? await sessionManager.saveSession(updatedSession)
        }
    }

    @MainActor
    private func loadProfileImage(from item: PhotosPickerItem?) async {
        guard let item else { return }

        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            profileImage = image
        }
    }
}

@MainActor
private final class ProfileScreenViewModel: ObservableObject {
    @Published var fullName: String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var dateOfBirth: Date = Date()
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var isSaving: Bool = false

    private let service: SidebarProfileServiceProtocol

    init(service: SidebarProfileServiceProtocol = SidebarProfileService()) {
        self.service = service
    }

    func load(session: AuthSession?) async {
        guard let session else {
            fullName = ""
            email = ""
            password = ""
            dateOfBirth = Date()
            errorMessage = nil
            successMessage = nil
            return
        }

        do {
            let details = try await service.fetchUserDetails(session: session)
            fullName = details.fullName
            email = details.email
            dateOfBirth = Self.profileDateFormatter.date(from: details.dateOfBirth) ?? Date()
            password = ""
            errorMessage = nil
            successMessage = nil
        } catch {
            fullName = session.userName
            email = session.userEmail
            dateOfBirth = Date()
            password = ""
            errorMessage = error.localizedDescription
        }
    }

    func save(session: AuthSession) async -> AuthSession? {
        isSaving = true
        defer { isSaving = false }

        do {
            let updatedDetails = try await service.saveUserDetails(
                session: session,
                fullName: fullName,
                email: email,
                dateOfBirth: Self.profileDateFormatter.string(from: dateOfBirth),
                password: password.isEmpty ? nil : password
            )

            password = ""
            errorMessage = nil
            successMessage = "Profile updated successfully."

            return AuthSession(
                accessToken: session.accessToken,
                refreshToken: session.refreshToken,
                userId: session.userId,
                userEmail: updatedDetails.email,
                userName: updatedDetails.fullName,
                expiresAt: session.expiresAt
            )
        } catch {
            errorMessage = error.localizedDescription
            successMessage = nil
            return nil
        }
    }

    private static let profileDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = .current
        formatter.locale = .current
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}
