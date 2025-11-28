import SwiftUI

struct MainTabView: View {
    enum Tab { case home, makeNoise, settings, search }

    @State private var currentUser: APIUser
    @State private var showMakeNoiseLive = false
    @Namespace private var gridNamespace
    @State private var selectedGridItem: Recording? = nil

    let onLogout: () -> Void

    init(user: APIUser, onLogout: @escaping () -> Void) {
        _currentUser = State(initialValue: user)
        self.onLogout = onLogout
    }

    var body: some View {
        TabView {
            NavigationStack {
                ZStack(alignment: .bottom) {
                    HomeView(
                        user: currentUser,
                        onSelectDetail: { recording in
                            selectedGridItem = recording
                        },
                        namespace: gridNamespace
                    )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemBackground))

                    // Floating Make Noise button
                    Button {
                        showMakeNoiseLive = true
                    } label: {
                        Text("Make Noise")
                            .font(.headline)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.accentColor, in: Capsule())
                            .foregroundColor(.white)
                            .shadow(radius: 4)
                    }
                    .padding(.bottom, 16)
                }
            }
            .tabItem { Image(systemName: "house.fill") }

            NavigationStack {
                SearchView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
            }
            .tabItem { Image(systemName: "magnifyingglass") }

            NavigationStack {
                SettingsView(
                    user: currentUser,
                    onUserUpdated: { updated in currentUser = updated },
                    onLogout: onLogout
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
            }
            .tabItem { Image(systemName: "gearshape.fill") }
        }
        .fullScreenCover(isPresented: $showMakeNoiseLive) {
            MakeNoiseLiveView { showMakeNoiseLive = false }
                .ignoresSafeArea()
        }
        .overlay {
            if let item = selectedGridItem {
                ZStack {
                    Color.clear
                        .ignoresSafeArea()
                        .onTapGesture { selectedGridItem = nil }
                    LiveDetailView(
                        recording: item,
                        namespace: gridNamespace
                    ) {
                        selectedGridItem = nil
                    }
                    .ignoresSafeArea()
                }
                .zIndex(1000)
                .transition(.opacity)
                .animation(.easeInOut, value: selectedGridItem != nil)
            }
        }
    }
}

struct MakeNoiseView: View {
    let onMakeNoiseLive: () -> Void

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                Text("Make Noise")
                    .font(.title2.bold())
                Text("Coming soon")
                    .foregroundColor(.secondary)
                Button {
                    onMakeNoiseLive()
                } label: {
                    Text("Make Noise")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
        }
    }
}

struct MakeNoiseLiveView: View {
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            VStack {
                Text("Make Noise Live")
                    .font(.largeTitle.bold())
                Spacer()
                Button("Dismiss") {
                    onDismiss()
                }
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding()
            }
            .navigationBarHidden(true)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
        }
    }
}

struct SearchView: View {
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if searchText.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 60))
                                .foregroundColor(.secondary)
                            Text("Search Noise")
                                .font(.title2.bold())
                            Text("Find people and recordings")
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 100)
                    } else {
                        // Search results go here
                        VStack {
                            Text("Searching for: \(searchText)")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search recordings and people"
            )
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
