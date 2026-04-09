import SwiftUI

struct SignUpScreen: View {
    @ObservedObject var viewModel: AuthViewModel
    let onSignUpSuccess: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var dateOfBirth = Date()
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        ZStack {
            Color.travelBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    topArt

                    Text("Sign up")
                        .font(.largeTitle.bold())
                        .foregroundStyle(Color.travelTitle)

                    Text("Sign up to enjoy the feature of TravelBuddy")
                        .font(.subheadline)
                        .foregroundStyle(Color.travelBody)

                    if let message = viewModel.errorMessage {
                        AuthErrorBanner(message: message)
                    }

                    AuthInputField(title: "Your Name", text: $name)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Date of Birth")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.travelTitle)

                        DatePicker(
                            "",
                            selection: $dateOfBirth,
                            displayedComponents: .date
                        )
                        .labelsHidden()
                        .frame(maxWidth: .infinity, alignment: .leading)
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

                    AuthInputField(title: "Email", text: $email, keyboardType: .emailAddress)
                    AuthSecureInputField(title: "Password", text: $password)

                    AuthPrimaryButton(title: "Sign up", isLoading: viewModel.isLoading) {
                        Task {
                            let success = await viewModel.register(name: name, email: email, password: password)
                            if success {
                                onSignUpSuccess()
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
                            Text("Continue with Google")
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
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundStyle(Color.travelTitle)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    private var topArt: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.65))
                .frame(height: 160)

            HStack(spacing: 24) {
                Image(systemName: "person.fill")
                    .font(.system(size: 42))
                    .foregroundStyle(Color(red: 0.95, green: 0.57, blue: 0.62))

                Image(systemName: "person.fill.badge.plus")
                    .font(.system(size: 44))
                    .foregroundStyle(Color(red: 0.26, green: 0.58, blue: 0.89))
            }

            Image(systemName: "location.fill")
                .font(.subheadline)
                .foregroundStyle(Color(red: 0.97, green: 0.52, blue: 0.44))
                .offset(x: -94, y: -52)

            Image(systemName: "location.fill")
                .font(.subheadline)
                .foregroundStyle(Color(red: 0.48, green: 0.40, blue: 0.89))
                .offset(x: 94, y: 50)
        }
    }
}
