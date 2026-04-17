import SwiftUI
import UIKit

struct SignInScreen: View {
    @ObservedObject var viewModel: AuthViewModel
    let onCreateAccount: () -> Void
    let onForgotPassword: () -> Void
    let onLoginSuccess: () -> Void

    @State private var email = ""
    @State private var password = ""

    private var canSubmit: Bool {
        email.trimmingCharacters(in: .whitespacesAndNewlines).contains("@")
        && password.count >= 8
        && !viewModel.isLoading
    }

    var body: some View {
        ZStack {
            Color.travelBackground.ignoresSafeArea()

            GeometryReader { geometry in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        topArt

                        Text("Sign in")
                            .font(.largeTitle.bold())
                            .foregroundStyle(Color.travelTitle)

                        Text("Please login to continue to your account.")
                            .font(.subheadline)
                            .foregroundStyle(Color.travelBody)

                        if let message = viewModel.errorMessage {
                            AuthErrorBanner(message: message)
                        }

                        if let message = viewModel.successMessage {
                            AuthSuccessBanner(message: message)
                        }

                        AuthInputField(title: "Email", text: $email, keyboardType: .emailAddress)

                        AuthSecureInputField(title: "Password", text: $password)

                        HStack {
                            Spacer()
                            Button("Forgot Password?") {
                                viewModel.clearError()
                                onForgotPassword()
                            }
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Color.travelTitle)
                        }

                        Spacer(minLength: 20)

                        VStack(spacing: 16) {
                            AuthPrimaryButton(title: "Sign in", isLoading: viewModel.isLoading) {
                                guard canSubmit else { return }

                                let normalizedEmail = email
                                    .trimmingCharacters(in: .whitespacesAndNewlines)
                                    .lowercased()

                                Task {
                                    let success = await viewModel.login(email: normalizedEmail, password: password)
                                    if success {
                                        onLoginSuccess()
                                    }
                                }
                            }
                            .opacity(canSubmit ? 1 : 0.7)
                            .disabled(!canSubmit)

                            HStack {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.35))
                                    .frame(height: 1)
                                Text("or")
                                    .font(.footnote)
                                    .foregroundStyle(Color.travelBody)
                                Rectangle()
                                    .fill(Color.gray.opacity(0.35))
                                    .frame(height: 1)
                            }

                            Button {
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "g.circle.fill")
                                        .font(.title3)
                                    Text("Sign in with Google")
                                        .font(.headline)
                                }
                                .foregroundStyle(Color.travelTitle)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(Color.white.opacity(0.9))
                                )
                            }
                            .buttonStyle(.plain)

                            HStack(spacing: 6) {
                                Text("Need an account?")
                                    .foregroundStyle(Color.travelBody)
                                Button("Create one") {
                                    viewModel.clearError()
                                    onCreateAccount()
                                }
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.travelPrimary)
                            }
                            .font(.body)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 4)
                        }
                    }
                    .frame(minHeight: geometry.size.height - 40, alignment: .top)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                }
            }
        }
    }

    private var topArt: some View {
        ZStack {
            Group {
                if let uiImage = loadSignInHeaderImage() {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                } else {
                    HStack(spacing: 28) {
                        VStack(spacing: 10) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 34))
                                .foregroundStyle(Color(red: 0.87, green: 0.45, blue: 0.65))
                            Image(systemName: "suitcase.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(Color(red: 0.98, green: 0.66, blue: 0.30))
                        }

                        VStack(spacing: 10) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 34))
                                .foregroundStyle(Color(red: 0.25, green: 0.56, blue: 0.87))
                            Image(systemName: "suitcase.rolling.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(Color(red: 0.98, green: 0.58, blue: 0.29))
                        }
                    }

                    Image(systemName: "airplane")
                        .font(.headline)
                        .foregroundStyle(Color.travelPrimary.opacity(0.7))
                        .offset(x: 0, y: -56)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 220)
    }

    private func loadSignInHeaderImage() -> UIImage? {
        let candidates: [(String, String?, String?)] = [
            ("9372541 1", "png", nil),
            ("9372541 1.png", nil, nil),
            ("93725411", "png", nil),
            ("93725411.png", nil, nil),
            ("9372541 1", "png", "Icons"),
            ("9372541 1.png", nil, "Icons"),
            ("93725411", "png", "Icons"),
            ("93725411.png", nil, "Icons"),
            ("Assets/Icons/9372541 1", "png", nil),
            ("Assets/Icons/9372541 1.png", nil, nil),
            ("Assets/Icons/93725411", "png", nil),
            ("Assets/Icons/93725411.png", nil, nil),
            ("Image", "png", nil),
            ("Image.png", nil, nil),
            ("Image", "png", "Icons"),
            ("Image.png", nil, "Icons"),
            ("Assets/Icons/Image", "png", nil),
            ("Assets/Icons/Image.png", nil, nil)
        ]

        for (name, ext, directory) in candidates {
            if let path = Bundle.main.path(forResource: name, ofType: ext, inDirectory: directory),
               let image = UIImage(contentsOfFile: path) {
                return image
            }
        }

        return UIImage(named: "9372541 1")
            ?? UIImage(named: "9372541 1.png")
            ?? UIImage(named: "93725411")
            ?? UIImage(named: "93725411.png")
            ?? UIImage(named: "Image")
            ?? UIImage(named: "Image.png")
    }
}
