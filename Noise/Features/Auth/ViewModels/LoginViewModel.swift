import Foundation
import Combine

final class LoginViewModel: ObservableObject {
    @Published var emailOrUsername: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let apiClient: APIClient
    private let onLogin: (APIUser) -> Void

    init(apiClient: APIClient = .shared, onLogin: @escaping (APIUser) -> Void) {
        self.apiClient = apiClient
        self.onLogin = onLogin
    }

    var isLoginEnabled: Bool {
        !emailOrUsername.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !isLoading
    }

    @MainActor
    func login() {
        guard isLoginEnabled else { return }
        errorMessage = nil
        isLoading = true

        Task { [weak self] in
            guard let self else { return }

            do {
                _ = try await apiClient.login(
                    emailOrUsername: emailOrUsername.trimmingCharacters(in: .whitespacesAndNewlines),
                    password: password
                )
                let user = try await apiClient.fetchCurrentUser()
                await MainActor.run {
                    self.onLogin(user)
                }
            } catch {
                if let apiError = error as? APIClientError {
                    await MainActor.run {
                        self.errorMessage = apiError.localizedDescription
                    }
                } else {
                    await MainActor.run {
                        self.errorMessage = "Unable to login. Please try again later."
                    }
                }
            }

            await MainActor.run {
                self.isLoading = false
            }
        }
    }
}
