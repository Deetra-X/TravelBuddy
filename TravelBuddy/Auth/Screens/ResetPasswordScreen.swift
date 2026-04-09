import SwiftUI

struct ResetPasswordScreen: View {
    @ObservedObject var viewModel: AuthViewModel
    let onPasswordResetDone: () -> Void

    @State private var newPassword = ""
    @State private var confirmPassword = ""

    var body: some View {
        ZStack {
            Color.travelBackground.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                topArt
                    .padding(.top, 12)

                Text("Reset Password")
                    .font(.title.bold())
                    .foregroundStyle(Color.travelTitle)

                Text("Create your new password after OTP verification.")
                    .font(.subheadline)
                    .foregroundStyle(Color.travelBody)

                if let message = viewModel.errorMessage {
                    AuthErrorBanner(message: message)
                }

                AuthSecureInputField(title: "New Password", text: $newPassword)
                AuthSecureInputField(title: "Re-enter Password", text: $confirmPassword)

                AuthPrimaryButton(title: "Reset Password", isLoading: viewModel.isLoading) {
                    Task {
                        let success = await viewModel.resetPassword(newPassword: newPassword, confirmPassword: confirmPassword)
                        if success {
                            onPasswordResetDone()
                        }
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
    }

    private var topArt: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.65))
                .frame(height: 160)

            Image(systemName: "lock.rotation")
                .font(.system(size: 60))
                .foregroundStyle(Color(red: 0.47, green: 0.78, blue: 0.83))
        }
    }
}
