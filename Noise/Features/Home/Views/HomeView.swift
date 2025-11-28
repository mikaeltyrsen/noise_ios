import SwiftUI

struct HomeView: View {
    let user: APIUser
    let onSelectDetail: (LiveBroadcast) -> Void
    let namespace: Namespace.ID

    @StateObject private var viewModel = HomeFeedViewModel()

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 3)

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
                        }
                        .padding()

                        if viewModel.isLoading && viewModel.liveBroadcasts.isEmpty {
                            HStack {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                Text("Fetching live streams…")
                                    .foregroundStyle(.secondary)
                                    .font(.footnote)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 32)
                        }

                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.footnote)
                                .foregroundStyle(.red)
                                .padding(.horizontal)
                        }

                        if viewModel.liveBroadcasts.isEmpty && !viewModel.isLoading {
                            Text("No live streams right now. Pull to refresh.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal)
                        }

                        LazyVGrid(columns: columns, spacing: 0) {
                            ForEach(viewModel.liveBroadcasts) { broadcast in
                                LiveBroadcastGridItem(broadcast: broadcast, namespace: namespace)
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                                            onSelectDetail(broadcast)
                                        }
                                    }
                            }
                        }
                        .padding(.bottom, 12)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .task(viewModel.fetchFeed)
        .refreshable { await viewModel.fetchFeed() }
    }
}

private struct LiveBroadcastGridItem: View {
    let broadcast: LiveBroadcast
    let namespace: Namespace.ID

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 0)
                .fill(Color(hue: 1.0, saturation: 0.0, brightness: 0.231))
                .matchedGeometryEffect(id: broadcast.id, in: namespace)
                .overlay(
                    LiveVideoPreview(stream: broadcast)
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

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    if let avatarURL = broadcast.avatarURL, let url = URL(string: avatarURL) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Color.white.opacity(0.2)
                        }
                        .frame(width: 18, height: 18)
                        .clipShape(Circle())
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(broadcast.displayName?.isEmpty == false ? (broadcast.displayName ?? broadcast.username) : broadcast.username)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        if let title = broadcast.title, !title.isEmpty {
                            Text(title)
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(1)
                        }
                    }
                    Spacer()
                }

                HStack(spacing: 6) {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.white)
                    Text("\(broadcast.viewerCount)")
                        .font(.system(size: 10))
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "rectangle.expand.vertical")
                        .font(.system(size: 10))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .padding(10)
        }
        .aspectRatio(3.0 / 4.0, contentMode: .fit)
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
    ), onSelectDetail: { _ in }, namespace: Namespace().wrappedValue)
}
