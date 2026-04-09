import SwiftUI

private enum AuthRoute: Hashable {
    case signUp
    case forgotPassword
    case otp
    case resetPassword
    case success
}

struct AuthFlowView: View {
    let onLoginSuccess: () -> Void

    @StateObject private var viewModel = AuthViewModel()
    @State private var path: [AuthRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            SignInScreen(
                viewModel: viewModel,
                onCreateAccount: {
                    viewModel.clearError()
                    path.append(.signUp)
                },
                onForgotPassword: {
                    viewModel.clearError()
                    path.append(.forgotPassword)
                },
                onLoginSuccess: onLoginSuccess
            )
            .navigationDestination(for: AuthRoute.self) { route in
                switch route {
                case .signUp:
                    SignUpScreen(
                        viewModel: viewModel,
                        onSignUpSuccess: onLoginSuccess,
                        onTemporaryHome: onLoginSuccess
                    )
                case .forgotPassword:
                    ForgotPasswordScreen(
                        viewModel: viewModel,
                        onCodeSent: {
                            viewModel.clearError()
                            path.append(.otp)
                        }
                    )
                case .otp:
                    OTPVerificationScreen(
                        viewModel: viewModel,
                        onOTPVerified: {
                            viewModel.clearError()
                            path.append(.resetPassword)
                        }
                    )
                case .resetPassword:
                    ResetPasswordScreen(
                        viewModel: viewModel,
                        onPasswordResetDone: {
                            viewModel.clearError()
                            path.append(.success)
                        }
                    )
                case .success:
                    AuthSuccessScreen {
                        viewModel.clearError()
                        path = []
                    }
                }
            }
        }
    }
}
