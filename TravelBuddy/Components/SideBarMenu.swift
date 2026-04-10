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
                    Text("Deenath")
                        .font(.subheadline)
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
                .font(.subheadline)
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
