import SwiftUI

private enum AuthRoute: Hashable {
    case signUp
    case forgotPassword
    case otp
    case resetPassword
    case success
    case preferences
    case preferencesSuccess
}

struct AuthFlowView: View {
    let onLoginSuccess: () -> Void

    @StateObject private var viewModel = AuthViewModel()
    @StateObject private var preferencesViewModel = UserPreferencesViewModel()
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
                onLoginSuccess: {
                    // Navigate to preferences instead of directly logging in
                    viewModel.clearError()
                    path.append(.preferences)
                }
            )
            .navigationDestination(for: AuthRoute.self) { route in
                switch route {
                case .signUp:
                    SignUpScreen(
                        viewModel: viewModel,
                        onSignUpSuccess: {
                            viewModel.clearError()
                            path.append(.preferences)
                        },
                        onTemporaryHome: {
                            viewModel.clearError()
                            path.append(.preferences)
                        }
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
                case .preferences:
                    UserPreferencesScreen(
                        viewModel: preferencesViewModel,
                        onPreferencesSelected: {
                            path.append(.preferencesSuccess)
                        },
                        onSkip: {
                            path.append(.preferencesSuccess)
                        }
                    )
                case .preferencesSuccess:
                    UserPreferencesSuccessScreen(
                        viewModel: preferencesViewModel,
                        onComplete: {
                            onLoginSuccess()
                        }
                    )
                }
            }
        }
    }
}
