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
        TabView(selection: $selectedTab) {
            HomeView(user: currentUser)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(Tab.home)

            MakeNoiseView()
                .tabItem {
                    Label("Make Noise", systemImage: "plus.circle.fill")
                }
                .tag(Tab.makeNoise)

            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(Tab.search)

            SettingsView(
                user: currentUser,
                onUserUpdated: { updated in currentUser = updated },
                onLogout: onLogout
            )
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(Tab.settings)
        }
        .tabViewStyle(.automatic)
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
