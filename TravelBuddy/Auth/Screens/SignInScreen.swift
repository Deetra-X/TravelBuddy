import SwiftUI

struct SignInScreen: View {
    @ObservedObject var viewModel: AuthViewModel
    let onCreateAccount: () -> Void
    let onForgotPassword: () -> Void
    let onLoginSuccess: () -> Void

    @State private var email = ""
    @State private var password = ""

    var body: some View {
        ZStack {
            Color.travelBackground.ignoresSafeArea()

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

                    AuthPrimaryButton(title: "Sign in", isLoading: viewModel.isLoading) {
                        Task {
                            let success = await viewModel.login(email: email, password: password)
                            if success {
                                onLoginSuccess()
                            }
                        }
                    }

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
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
        }
    }

    private var topArt: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.65))
                .frame(height: 160)

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
}
