import SwiftUI
import UIKit

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

                Spacer()

                AuthPrimaryButton(title: "Verify OTP", isLoading: viewModel.isLoading) {
                    Task {
                        let success = await viewModel.verifyPasswordResetCode(code: otpCode)
                        if success {
                            onOTPVerified()
                        }
                    }
                }
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
            Group {
                if let uiImage = loadVerificationHeaderImage() {
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

    private func loadVerificationHeaderImage() -> UIImage? {
        let candidates: [(String, String?, String?)] = [
            ("verifi", "png", nil),
            ("verifi.png", nil, nil),
            ("verifi", "png", "Icons"),
            ("verifi.png", nil, "Icons"),
            ("Assets/Icons/verifi", "png", nil),
            ("Assets/Icons/verifi.png", nil, nil)
        ]

        for (name, ext, directory) in candidates {
            if let path = Bundle.main.path(forResource: name, ofType: ext, inDirectory: directory),
               let image = UIImage(contentsOfFile: path) {
                return image
            }
        }

        return UIImage(named: "verifi") ?? UIImage(named: "verifi.png")
    }
}
