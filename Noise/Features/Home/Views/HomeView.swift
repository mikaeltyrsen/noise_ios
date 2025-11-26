import SwiftUI

struct HomeView: View {
    let user: APIUser
    var onLogout: () -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 1), count: 3)

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 24) {
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
                    }.padding()

                    LazyVGrid(columns: columns, spacing: 1) {
                        ForEach(0..<40) { index in
                            RecordingGridItem(title: "Recording #\(index + 1)")
                        }
                    }.padding(1)
                }
                //.padding(1)
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

private struct RecordingGridItem: View {
    let title: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 0)
                .fill(Color.gray.opacity(0.25))
                .overlay(
                    ProceduralNoiseView()
                        .clipShape(RoundedRectangle(cornerRadius: 0))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 0)
                        .fill(
                            LinearGradient(
                                colors: [Color.black.opacity(0.2), Color.black.opacity(0)],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                )

            VStack(spacing: 8) {
                Image(systemName: "waveform")
                    .font(.title2)
                    .foregroundColor(.white)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        }
        .aspectRatio(3.0 / 4.0, contentMode: .fit)
        //.shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 4)
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
