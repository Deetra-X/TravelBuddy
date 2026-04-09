import SwiftUI

struct ForgotPasswordScreen: View {
    @ObservedObject var viewModel: AuthViewModel
    let onCodeSent: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var email = ""

    var body: some View {
        ZStack {
            Color.travelBackground.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                topArt
                    .padding(.top, 12)

                Text("Forgot Password")
                    .font(.title.bold())
                    .foregroundStyle(Color.travelTitle)

                Text("Enter your email and we will send you a verification code.")
                    .font(.subheadline)
                    .foregroundStyle(Color.travelBody)

                if let message = viewModel.errorMessage {
                    AuthErrorBanner(message: message)
                }

                AuthInputField(title: "Email", text: $email, keyboardType: .emailAddress)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Password Requirement:")
                        .font(.headline)
                        .foregroundStyle(Color.travelTitle)

                    Text("• At least 8 characters")
                    Text("• No part of your username")
                    Text("• Cannot match your last 4 passwords")
                }
                .font(.footnote)
                .foregroundStyle(Color.travelTitle.opacity(0.85))

                AuthPrimaryButton(title: "Send Code", isLoading: viewModel.isLoading) {
                    Task {
                        let success = await viewModel.requestPasswordResetCode(email: email)
                        if success {
                            onCodeSent()
                        }
                    }
                }

                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                        Text("Back to Sign in")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.travelTitle)
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
        .navigationBarBackButtonHidden(true)
    }

    private var topArt: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.65))
                .frame(height: 160)

            Image(systemName: "person.text.rectangle.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color(red: 0.47, green: 0.78, blue: 0.83))

            Image(systemName: "person.fill")
                .font(.system(size: 28))
                .foregroundStyle(.white)
                .offset(x: -18, y: -14)
        }
    }
}
