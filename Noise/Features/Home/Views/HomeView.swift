import SwiftUI

struct HomeView: View {
    let user: APIUser

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 3)
    private let recordings = (0..<40).map { Recording(id: $0, title: "1,34\($0 + 1)") }

    @Namespace private var namespace
    @State private var selectedRecording: Recording?

    var body: some View {
        NavigationView {
            ZStack {
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

                        LazyVGrid(columns: columns, spacing: 0) {
                            ForEach(recordings) { recording in
                                RecordingGridItem(recording: recording, namespace: namespace)
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                                            selectedRecording = recording
                                        }
                                    }
                            }
                        }.padding(0)
                    }
                    //.padding(1)
                }
                //.navigationTitle("Home")

                if let selectedRecording {
                    LiveDetailView(recording: selectedRecording, namespace: namespace) {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                            self.selectedRecording = nil
                        }
                    }
                    .transition(.opacity)
                    .zIndex(1)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct Recording: Identifiable, Equatable {
    let id: Int
    let title: String
}

private struct RecordingGridItem: View {
    let recording: Recording
    let namespace: Namespace.ID

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 0)
                .fill(Color(hue: 1.0, saturation: 0.0, brightness: 0.231))
                .matchedGeometryEffect(id: recording.id, in: namespace)
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
                    Text(recording.title)
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
        followingCount: 64,
        bio: "Bio",
        website: "https://example.com",
        isPrivate: false
    ))
}
