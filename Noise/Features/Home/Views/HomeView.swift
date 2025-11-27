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
                        HStack(spacing: 12) {
                            AvatarView(avatarURL: user.avatarURL, size: 50)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.username)
                                    .font(.title2)
                                    .fontWeight(.bold)

                                if let displayName = user.displayName {
                                    Text(displayName)
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            HStack(spacing: 20) {
                                StatView(title: "Followers", value: user.followerCount)
                                StatView(title: "Following", value: user.followingCount)
                            }

                        }

                        
                    }.padding()

                    LazyVGrid(columns: columns, spacing: 1) {
                        ForEach(0..<40) { index in
                            RecordingGridItem(title: "1,34\(index + 1)")
                        }
                    }.padding(1)
                }
                //.padding(1)
            }
            //.navigationTitle("Home")
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
                .fill(Color(hue: 1.0, saturation: 0.0, brightness: 0.231))
                .overlay(
                    ProceduralNoiseView()
                        .clipShape(RoundedRectangle(cornerRadius: 0))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 0)
                        .fill(
                            LinearGradient(
                                colors: [Color.black.opacity(0.5), Color.black.opacity(0)],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                )

            HStack( spacing: 3) {
                //AvatarView(avatarURL: "", size: 15)
                HStack( spacing: 3) {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.white)
                    Text(title)
                        .font(.system(size: 10))
                        .foregroundColor(.white)
                }
                Spacer()
                Image(systemName: "rectangle.expand.vertical")
                    .font(.system(size: 10))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .padding(10)
        }
        .aspectRatio(3.0 / 4.0, contentMode: .fit)
        //.shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 4)
    }
}

private struct AvatarView: View {
    let avatarURL: String?
    let size: CGFloat

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
                    .fill(Color.accentColor.opacity(1))
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

private struct StatView: View {
    let title: String
    let value: Int

    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Text("\(value)")
                .font(.title3.bold())
                .foregroundColor(.primary)
            Text(title)
                .lineLimit(1)
                .allowsTightening(true)
                .truncationMode(.tail)
                .font(.footnote)
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
