import Foundation
import Combine

final class LoginViewModel: ObservableObject {
    @Published var emailOrUsername: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let apiClient: APIClient

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
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
                // Handle successful login flow, e.g., navigate to the main app experience.
            } catch {
                if let apiError = error as? APIClientError {
                    self.errorMessage = apiError.localizedDescription
                } else {
                    self.errorMessage = "Unable to login. Please try again later."
                }
            }

            self.isLoading = false
        }
    }
}
