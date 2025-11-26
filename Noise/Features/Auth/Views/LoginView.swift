import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel: LoginViewModel

    init(onLogin: @escaping (APIUser) -> Void) {
        _viewModel = StateObject(wrappedValue: LoginViewModel(onLogin: onLogin))
    }

    var body: some View {
        ZStack {
            BackgroundVideoView()
                .opacity(0.85)
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("Welcome to Noise")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("Sign in to see which friends are making noise right now.")
                        .foregroundColor(.white.opacity(0.8))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                VStack(spacing: 16) {
                    TextField("Email or Username", text: $viewModel.emailOrUsername)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.none)
                        .autocorrectionDisabled(true)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.25))
                                .background(Color.white.opacity(0.08).cornerRadius(12))
                        )
                        .colorScheme(.dark)

                    SecureField("Password", text: $viewModel.password)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.25))
                                .background(Color.white.opacity(0.08).cornerRadius(12))
                        )
                        .colorScheme(.dark)
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button(action: viewModel.login) {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Login")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(viewModel.isLoginEnabled ? Color.blue : Color.white.opacity(0.25))
                .foregroundColor(.white)
                .cornerRadius(14)
                .disabled(!viewModel.isLoginEnabled)

                Spacer()

                HStack(spacing: 4) {
                    Text("Don't have an account?")
                        .foregroundColor(.white.opacity(0.8))
                    Button("Sign up") {
                        // Navigate to sign up flow
                    }
                    .font(.callout.bold())
                }
            }
            .padding()
        }
        .background(Color.black)
    }
}

#Preview {
    LoginView { _ in }
}
