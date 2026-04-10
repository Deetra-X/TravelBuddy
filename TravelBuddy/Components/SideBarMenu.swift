import SwiftUI

struct SideBarMenu: View {
    var onClose: () -> Void
    var onLogout: () -> Void
    var onAdvancedSettings: () -> Void

    @State private var locationEnabled = true
    @State private var pushEnabled = false
    @State private var selectedLanguage = "English"

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack {
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.headline)
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
                    Text("Deenath")
                        .font(.headline)
                    Text("deenath@gmail.com")
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
                .font(.headline)
                .padding(.top, 4)

            menuRow(icon: "location", title: "Location") {
                Toggle("", isOn: $locationEnabled)
                    .labelsHidden()
                    .tint(Color.travelPrimary)
            }

            menuRow(icon: "globe", title: "Language") {
                Menu {
                    Button("English") {
                        selectedLanguage = "English"
                    }
                    Button("Spanish") {
                        selectedLanguage = "Spanish"
                    }
                    Button("French") {
                        selectedLanguage = "French"
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(selectedLanguage)
                            .font(.subheadline)
                            .foregroundStyle(Color.travelBody)
                        Image(systemName: "chevron.right")
                            .foregroundStyle(Color.travelTitle)
                    }
                }
            }

            menuRow(icon: "bell", title: "Push Notifications") {
                Toggle("", isOn: $pushEnabled)
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
                HStack(spacing: 10) {
                    Image(systemName: "rectangle.portrait.and.arrow.forward")
                    Text("Logout")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.travelPrimary)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: 320, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.travelBackground)
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
