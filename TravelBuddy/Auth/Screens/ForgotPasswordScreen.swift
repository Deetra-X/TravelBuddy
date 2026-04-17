import SwiftUI
import UIKit

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

                Spacer()

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
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
        .navigationBarBackButtonHidden(true)
    }

    private var topArt: some View {
        ZStack {
            Group {
                if let uiImage = loadForgotPasswordHeaderImage() {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 220)
    }

    private func loadForgotPasswordHeaderImage() -> UIImage? {
        let candidates: [(String, String?, String?)] = [
            ("Forgot_password-r", "png", nil),
            ("Forgot_password-r.png", nil, nil),
            ("Forgot_password-r", "png", "Icons"),
            ("Forgot_password-r.png", nil, "Icons"),
            ("Assets/Icons/Forgot_password-r", "png", nil),
            ("Assets/Icons/Forgot_password-r.png", nil, nil)
        ]

        for (name, ext, directory) in candidates {
            if let path = Bundle.main.path(forResource: name, ofType: ext, inDirectory: directory),
               let image = UIImage(contentsOfFile: path) {
                return image
            }
        }

        return UIImage(named: "Forgot_password-r") ?? UIImage(named: "Forgot_password-r.png")
    }
}
