import SwiftUI

struct HomeView: View {
    let user: APIUser
    var onLogout: () -> Void

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Welcome back")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text(user.displayName ?? user.username)
                            .font(.largeTitle.bold())
                    }

                    Text("Live recordings will appear here in a grid.")
                        .foregroundColor(.secondary)

                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(0..<6) { index in
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.15))
                                .frame(height: 120)
                                .overlay(
                                    VStack {
                                        Image(systemName: "waveform")
                                            .font(.title)
                                            .foregroundColor(.blue)
                                        Text("Recording #\(index + 1)")
                                            .foregroundColor(.secondary)
                                    }
                                )
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Logout", action: onLogout)
                }
            }
        }
    }
}

#Preview {
    HomeView(user: APIUser(
        id: "example-id",
        email: "user@example.com",
        username: "example",
        displayName: "Example User",
        avatarURL: nil,
        status: "active"
    )) { }
}
