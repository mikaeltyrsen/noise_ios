import SwiftUI

struct ContentView: View {
    @State private var currentUser: APIUser?

    var body: some View {
        if let user = currentUser {
            HomeView(user: user) {
                APIClient.shared.clearAuthToken()
                currentUser = nil
            }
        } else {
            LoginView { user in
                currentUser = user
            }
        }
    }
}

#Preview {
    ContentView()
}
