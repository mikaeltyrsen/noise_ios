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
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            AvatarView(avatarURL: user.avatarURL)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.username)
                                    .font(.largeTitle.bold())

                                if let displayName = user.displayName {
                                    Text(displayName)
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()
                        }

                        HStack {
                            StatView(title: "Followers", value: user.followerCount)
                            Spacer()
                            StatView(title: "Following", value: user.followingCount)
                        }
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

private struct AvatarView: View {
    let avatarURL: String?

    var body: some View {
        Group {
            if let avatarURL, let url = URL(string: avatarURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    ProgressView()
                }
            } else {
                Circle()
                    .fill(Color.blue.opacity(0.3))
            }
        }
        .frame(width: 64, height: 64)
        .clipShape(Circle())
    }
}

private struct StatView: View {
    let title: String
    let value: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(value)")
                .font(.title3.bold())
                .foregroundColor(.primary)
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
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
        status: "active",
        followerCount: 128,
        followingCount: 64
    )) { }
}
