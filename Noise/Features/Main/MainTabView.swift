import SwiftUI

struct MainTabView: View {
    enum Tab { case home, makeNoise, search, settings }

    @State private var selectedTab: Tab = .home
    @State private var currentUser: APIUser

    let onLogout: () -> Void

    init(user: APIUser, onLogout: @escaping () -> Void) {
        _currentUser = State(initialValue: user)
        self.onLogout = onLogout
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .home:
                    HomeView(user: currentUser)
                case .makeNoise:
                    MakeNoiseView()
                case .search:
                    SearchView()
                case .settings:
                    SettingsView(
                        user: currentUser,
                        onUserUpdated: { updated in currentUser = updated },
                        onLogout: onLogout
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            FloatingTabBar(selectedTab: $selectedTab)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .animation(.easeInOut(duration: 0.2), value: selectedTab)
    }
}

private struct FloatingTabBar: View {
    @Binding var selectedTab: MainTabView.Tab

    private struct TabItem: Identifiable {
        let id: MainTabView.Tab
        let title: String
        let systemImage: String
    }

    private let items: [TabItem] = [
        .init(id: .home, title: "Home", systemImage: "house.fill"),
        .init(id: .makeNoise, title: "Make Noise", systemImage: "plus.circle.fill"),
        .init(id: .search, title: "Search", systemImage: "magnifyingglass"),
        .init(id: .settings, title: "Settings", systemImage: "gear")
    ]

    var body: some View {
        HStack(spacing: 12) {
            ForEach(items) { item in
                Button {
                    selectedTab = item.id
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: item.systemImage)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(selectedTab == item.id ? .primary : .secondary)
                        Text(item.title)
                            .font(.footnote.weight(.semibold))
                            .foregroundColor(selectedTab == item.id ? .primary : .secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(radius: 6, y: 2)
    }
}

struct MakeNoiseView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                Text("Make Noise")
                    .font(.title2.bold())
                Text("Coming soon")
                    .foregroundColor(.secondary)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
        }
    }
}

struct SearchView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                Text("Search")
                    .font(.title2.bold())
                Text("Coming soon")
                    .foregroundColor(.secondary)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
        }
    }
}

#Preview {
    MainTabView(user: APIUser(
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
    )) { }
}
