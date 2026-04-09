import SwiftUI
import PhotosUI
import UIKit

struct ProfileScreen: View {
    @State private var fullName = "Deenath Damsinghe"
    @State private var email = "ddeenath@gmail.com"
    @State private var password = "************"
    @State private var dateOfBirth = "12/12/2001"

    @State private var notificationsEnabled = false
    @State private var showDeleteAlert = false
    @State private var showClearHistoryAlert = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var profileImage: UIImage?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                topBar

                avatarSection

                Group {
                    inputField(title: "Name", text: $fullName)
                    inputField(title: "Email", text: $email)
                    inputField(title: "Password", text: $password)
                    dateOfBirthField
                }

                Button {
                } label: {
                    Text("Save")
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

                VStack(alignment: .leading, spacing: 14) {
                    Text("Additional Informations")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.travelTitle)

                    HStack {
                        Text("Notification")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Color.travelTitle)

                        Spacer()

                        Toggle("", isOn: $notificationsEnabled)
                            .labelsHidden()
                            .tint(Color.travelPrimary)
                    }

                    Button {
                        showClearHistoryAlert = true
                    } label: {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Clear History")
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(Color.travelTitle)

                                Text("Clear your wishlists and trip details and search history")
                                    .font(.footnote)
                                    .foregroundStyle(Color.travelBody)
                                    .multilineTextAlignment(.leading)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundStyle(Color.travelBody)
                                .padding(.top, 2)
                        }
                    }
                    .buttonStyle(.plain)

                    Button {
                        showDeleteAlert = true
                    } label: {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Delete Account")
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(.red)

                                Text("Permanently remove your account and data from Tripify, proceed with caution")
                                    .font(.footnote)
                                    .foregroundStyle(Color.travelBody)
                                    .multilineTextAlignment(.leading)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundStyle(Color.travelBody)
                                .padding(.top, 2)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 18)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 120)
        }
        .background(Color.travelBackground.ignoresSafeArea())
        .alert("Delete Account", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) { }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action cannot be undone.")
        }
        .alert("History Cleared", isPresented: $showClearHistoryAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your local history has been cleared.")
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

    private func inputField(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.travelTitle)

            TextField("", text: text)
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

            HStack {
                TextField("", text: $dateOfBirth)
                    .font(.body)

                Spacer()

                Image(systemName: "chevron.down")
                    .foregroundStyle(Color.travelTitle)
            }
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
    private func loadProfileImage(from item: PhotosPickerItem?) async {
        guard let item else { return }

        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            profileImage = image
        }
    }
}
