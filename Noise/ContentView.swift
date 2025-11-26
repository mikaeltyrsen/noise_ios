import SwiftUI

struct ContentView: View {
    @State private var currentUser: APIUser?
    @State private var isCheckingSession = true

    var body: some View {
        Group {
            if let user = currentUser {
                HomeView(user: user) {
                    APIClient.shared.clearAuthToken()
                    currentUser = nil
                }
            } else if isCheckingSession, APIClient.shared.authToken != nil {
                ProgressView()
            } else {
                LoginView { user in
                    currentUser = user
                    isCheckingSession = false
                }
            }
        }
        .task(loadExistingSession)
    }

    @Sendable
    private func loadExistingSession() async {
        guard isCheckingSession else { return }
        defer { isCheckingSession = false }

        guard APIClient.shared.authToken != nil else { return }

        do {
            let user = try await APIClient.shared.fetchCurrentUser()
            await MainActor.run {
                currentUser = user
            }
        } catch {
            APIClient.shared.clearAuthToken()
        }
    }
}

#Preview {
    ContentView()
}
