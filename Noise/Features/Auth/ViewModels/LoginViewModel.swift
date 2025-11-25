import Foundation
import Combine

final class LoginViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    var isLoginEnabled: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !isLoading
    }

    func login() {
        guard isLoginEnabled else { return }
        errorMessage = nil
        isLoading = true

        // Simulate a login request for now. Replace with APIManager once available.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            self.isLoading = false
            if self.email.lowercased() == "demo@noise.app" && self.password == "password" {
                // Handle successful login flow
            } else {
                self.errorMessage = "Invalid credentials. Please try again."
            }
        }
    }
}
