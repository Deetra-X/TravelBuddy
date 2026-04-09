import SwiftUI

struct AuthInputField: View {
    let title: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.travelTitle)

            TextField("Enter \(title.lowercased())", text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(keyboardType)
                .padding(.horizontal, 14)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.white.opacity(0.78))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.travelPrimary.opacity(0.65), lineWidth: 1)
                )
        }
    }
}

struct AuthSecureInputField: View {
    let title: String
    @Binding var text: String
    @State private var isSecure = true

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.travelTitle)

            HStack(spacing: 10) {
                Group {
                    if isSecure {
                        SecureField("Enter \(title.lowercased())", text: $text)
                    } else {
                        TextField("Enter \(title.lowercased())", text: $text)
                    }
                }
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

                Button {
                    isSecure.toggle()
                } label: {
                    Image(systemName: isSecure ? "eye.slash" : "eye")
                        .foregroundStyle(Color.gray)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.white.opacity(0.78))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.travelPrimary.opacity(0.65), lineWidth: 1)
            )
        }
    }
}

struct AuthPrimaryButton: View {
    let title: String
    let isLoading: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.travelPrimary)
                    .frame(height: 44)

                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.white)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

struct AuthErrorBanner: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.footnote)
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.red.opacity(0.12))
            )
    }
}
