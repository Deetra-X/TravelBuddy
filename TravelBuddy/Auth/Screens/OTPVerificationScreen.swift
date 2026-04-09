import SwiftUI

struct OTPVerificationScreen: View {
    @ObservedObject var viewModel: AuthViewModel
    let onOTPVerified: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var otpCode = ""

    var body: some View {
        ZStack {
            Color.travelBackground.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                topArt
                    .padding(.top, 12)

                Text("Verification Code")
                    .font(.title.bold())
                    .foregroundStyle(Color.travelTitle)

                Text("We have sent the verification code to your email. Enter OTP to continue.")
                    .font(.subheadline)
                    .foregroundStyle(Color.travelBody)

                if let message = viewModel.errorMessage {
                    AuthErrorBanner(message: message)
                }

                AuthInputField(title: "OTP", text: $otpCode, keyboardType: .numberPad)

                AuthPrimaryButton(title: "Verify OTP", isLoading: viewModel.isLoading) {
                    Task {
                        let success = await viewModel.verifyPasswordResetCode(code: otpCode)
                        if success {
                            onOTPVerified()
                        }
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
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

            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 62))
                .foregroundStyle(Color(red: 0.47, green: 0.78, blue: 0.83))
        }
    }
}
